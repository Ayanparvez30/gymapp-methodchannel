package com.example.gymapp

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.util.Log
import java.nio.charset.StandardCharsets

class HceService : HostApduService() {
    companion object {
        private const val TAG = "HceService"
        
        // NDEF Type 4 Tag Application AID
        private val NDEF_APP_AID = byteArrayOf(
            0xD2.toByte(), 0x76.toByte(), 0x00.toByte(), 0x00.toByte(),
            0x85.toByte(), 0x01.toByte(), 0x01.toByte()
        )
        
        // Capability Container file ID
        private val CC_FILE_ID = byteArrayOf(0xE1.toByte(), 0x03.toByte())
        
        // NDEF file ID  
        private val NDEF_FILE_ID = byteArrayOf(0xE1.toByte(), 0x04.toByte())
        
        // Response codes
        private val SUCCESS_RESPONSE = byteArrayOf(0x90.toByte(), 0x00.toByte())
        private val FILE_NOT_FOUND = byteArrayOf(0x6A.toByte(), 0x82.toByte())
        private val WRONG_LENGTH = byteArrayOf(0x67.toByte(), 0x00.toByte())
        private val UNKNOWN_COMMAND = byteArrayOf(0x6D.toByte(), 0x00.toByte())
        private val WRONG_PARAMS = byteArrayOf(0x6A.toByte(), 0x86.toByte())
        
        // Static variable to store the URI to be emulated
        var uriToEmulate: String? = null
        
        // State tracking
        private var isAppSelected = false
        private var selectedFileId: ByteArray? = null
    }
    
    override fun processCommandApdu(commandApdu: ByteArray?, extras: Bundle?): ByteArray {
        Log.d(TAG, "Received APDU: ${commandApdu?.let { bytesToHex(it) }}")
        
        commandApdu?.let { apdu ->
            if (apdu.size < 4) {
                Log.d(TAG, "APDU too short")
                return UNKNOWN_COMMAND
            }
            
            val cla = apdu[0]
            val ins = apdu[1]
            val p1 = apdu[2]
            val p2 = apdu[3]
            
            when {
                // SELECT command (CLA=00, INS=A4)
                cla == 0x00.toByte() && ins == 0xA4.toByte() -> {
                    return handleSelectCommand(p1, p2, apdu)
                }
                
                // READ BINARY command (CLA=00, INS=B0)
                cla == 0x00.toByte() && ins == 0xB0.toByte() -> {
                    return handleReadBinaryCommand(p1, p2, apdu)
                }
                
                else -> {
                    Log.d(TAG, "Unknown command: CLA=${bytesToHex(byteArrayOf(cla))}, INS=${bytesToHex(byteArrayOf(ins))}")
                    return UNKNOWN_COMMAND
                }
            }
        }
        
        return UNKNOWN_COMMAND
    }
    
    override fun onDeactivated(reason: Int) {
        Log.d(TAG, "Deactivated: $reason")
        isAppSelected = false
        selectedFileId = null
    }
    
    private fun handleSelectCommand(p1: Byte, p2: Byte, apdu: ByteArray): ByteArray {
        when {
            // SELECT application by AID (P1=04, P2=00)
            p1 == 0x04.toByte() && p2 == 0x00.toByte() -> {
                if (apdu.size < 5) return WRONG_LENGTH
                
                val lc = apdu[4].toInt() and 0xFF
                if (apdu.size < 5 + lc) return WRONG_LENGTH
                
                val aid = apdu.sliceArray(5 until 5 + lc)
                
                if (aid.contentEquals(NDEF_APP_AID)) {
                    Log.d(TAG, "NDEF Application selected")
                    isAppSelected = true
                    selectedFileId = null
                    return SUCCESS_RESPONSE
                } else {
                    Log.d(TAG, "Unknown AID: ${bytesToHex(aid)}")
                    return FILE_NOT_FOUND
                }
            }
            
            // SELECT file by file ID (P1=00, P2=0C)
            p1 == 0x00.toByte() && p2 == 0x0C.toByte() -> {
                if (!isAppSelected) {
                    Log.d(TAG, "Application not selected")
                    return WRONG_PARAMS
                }
                
                if (apdu.size < 5) return WRONG_LENGTH
                
                val lc = apdu[4].toInt() and 0xFF
                if (lc != 2 || apdu.size < 7) return WRONG_LENGTH
                
                val fileId = apdu.sliceArray(5..6)
                
                when {
                    fileId.contentEquals(CC_FILE_ID) -> {
                        Log.d(TAG, "Capability Container file selected")
                        selectedFileId = CC_FILE_ID
                        return SUCCESS_RESPONSE
                    }
                    fileId.contentEquals(NDEF_FILE_ID) -> {
                        Log.d(TAG, "NDEF file selected")
                        selectedFileId = NDEF_FILE_ID
                        return SUCCESS_RESPONSE
                    }
                    else -> {
                        Log.d(TAG, "Unknown file ID: ${bytesToHex(fileId)}")
                        return FILE_NOT_FOUND
                    }
                }
            }
            
            else -> {
                Log.d(TAG, "Unknown SELECT parameters: P1=${bytesToHex(byteArrayOf(p1))}, P2=${bytesToHex(byteArrayOf(p2))}")
                return WRONG_PARAMS
            }
        }
    }
    
    private fun handleReadBinaryCommand(p1: Byte, p2: Byte, apdu: ByteArray): ByteArray {
        if (!isAppSelected || selectedFileId == null) {
            Log.d(TAG, "No file selected")
            return WRONG_PARAMS
        }
        
        val offset = ((p1.toInt() and 0xFF) shl 8) or (p2.toInt() and 0xFF)
        val le = if (apdu.size > 4) apdu[4].toInt() and 0xFF else 0
        
        Log.d(TAG, "READ BINARY: offset=$offset, length=$le, fileId=${bytesToHex(selectedFileId!!)}")
        
        return when {
            selectedFileId!!.contentEquals(CC_FILE_ID) -> {
                val ccData = createCapabilityContainer()
                readFileData(ccData, offset, le)
            }
            selectedFileId!!.contentEquals(NDEF_FILE_ID) -> {
                val ndefData = createNdefFile()
                readFileData(ndefData, offset, le)
            }
            else -> FILE_NOT_FOUND
        }
    }
    
    private fun readFileData(fileData: ByteArray, offset: Int, length: Int): ByteArray {
        if (offset >= fileData.size) {
            return SUCCESS_RESPONSE // EOF
        }
        
        val actualLength = if (length == 0 || length > 255) {
            minOf(fileData.size - offset, 255)
        } else {
            minOf(fileData.size - offset, length)
        }
        
        val result = fileData.sliceArray(offset until offset + actualLength) + SUCCESS_RESPONSE
        Log.d(TAG, "Returning ${actualLength} bytes: ${bytesToHex(result)}")
        return result
    }
    
    private fun createCapabilityContainer(): ByteArray {
        // Capability Container for NDEF Type 4 Tag
        return byteArrayOf(
            0x00, 0x0F,  // CCLEN (15 bytes)
            0x20,        // Mapping Version (2.0)
            0x00, 0x3B,  // MLe (59 bytes max read)
            0x00, 0x34,  // MLc (52 bytes max write)
            0x04,        // NDEF File Control TLV Tag
            0x06,        // Length
            0xE1.toByte(), 0x04, // NDEF File ID
            0x00, 0xFF.toByte(),  // Maximum NDEF size (255 bytes)
            0x00,        // Read access (always)
            0x00         // Write access (always)
        )
    }
    
    private fun createNdefFile(): ByteArray {
        val uri = uriToEmulate ?: "https://devcenter.dev"
        Log.d(TAG, "Creating NDEF file for URI: $uri")
        
        // Create NDEF URI Record
        val ndefRecord = createNdefUriRecord(uri)
        
        // NDEF file format: [length][NDEF message]
        val ndefLength = ndefRecord.size
        val ndefFile = ByteArray(2 + ndefLength)
        
        // Write length as big-endian 16-bit value
        ndefFile[0] = (ndefLength shr 8).toByte()
        ndefFile[1] = (ndefLength and 0xFF).toByte()
        
        // Write NDEF message
        System.arraycopy(ndefRecord, 0, ndefFile, 2, ndefLength)
        
        Log.d(TAG, "NDEF file created: ${bytesToHex(ndefFile)}")
        return ndefFile
    }
    
    
    private fun createNdefUriRecord(uri: String): ByteArray {
        // NDEF URI Record format for Type 4 Tag
        val typeBytes = "U".toByteArray(StandardCharsets.UTF_8)
        
        // Determine URI identifier code for abbreviation
        val (uriIdentifier, abbreviatedUri) = when {
            uri.startsWith("https://www.") -> Pair(0x02.toByte(), uri.substring(12))
            uri.startsWith("http://www.") -> Pair(0x01.toByte(), uri.substring(11))
            uri.startsWith("https://") -> Pair(0x04.toByte(), uri.substring(8))
            uri.startsWith("http://") -> Pair(0x03.toByte(), uri.substring(7))
            else -> Pair(0x00.toByte(), uri)
        }
        
        val abbreviatedUriBytes = abbreviatedUri.toByteArray(StandardCharsets.UTF_8)
        val payloadBytes = byteArrayOf(uriIdentifier) + abbreviatedUriBytes
        
        // NDEF Record Header
        val flags = 0xD1.toByte() // MB=1, ME=1, CF=0, SR=1, IL=0, TNF=001 (Well-known)
        val typeLength = typeBytes.size.toByte()
        val payloadLength = payloadBytes.size.toByte()
        
        // Build complete NDEF record
        val record = mutableListOf<Byte>()
        record.add(flags)
        record.add(typeLength)
        record.add(payloadLength)
        record.addAll(typeBytes.toList())
        record.addAll(payloadBytes.toList())
        
        val result = record.toByteArray()
        Log.d(TAG, "Created NDEF URI record: ${bytesToHex(result)}")
        return result
    }
    
    private fun bytesToHex(bytes: ByteArray): String {
        return bytes.joinToString("") { "%02X".format(it) }
    }
}
