package com.example.gymapp

import android.content.Context
import android.nfc.NfcAdapter
import android.nfc.NfcManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.gymapp/nfc_hce"
    private lateinit var nfcAdapter: NfcAdapter
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize NFC adapter
        val nfcManager = getSystemService(Context.NFC_SERVICE) as NfcManager
        nfcAdapter = nfcManager.defaultAdapter
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNfcEnabled" -> {
                    try {
                        val isEnabled = nfcAdapter?.isEnabled ?: false
                        result.success(isEnabled)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                
                "isHceSupported" -> {
                    try {
                        // Check if NFC adapter exists and HCE is supported
                        val isSupported = nfcAdapter != null && 
                                         packageManager.hasSystemFeature("android.hardware.nfc.hce")
                        result.success(isSupported)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                
                "startHceEmulation" -> {
                    try {
                        val uri = call.argument<String>("uri") ?: "https://devcenter.dev"
                        
                        // Set the URI in the HCE service
                        HceService.uriToEmulate = uri
                        
                        // HCE service is automatically activated when another device comes close
                        // due to manifest registration
                        result.success("HCE emulation started with URI: $uri")
                    } catch (e: Exception) {
                        result.error("HCE_ERROR", "Failed to start HCE emulation: ${e.message}", null)
                    }
                }
                
                "stopHceEmulation" -> {
                    try {
                        // Clear the URI
                        HceService.uriToEmulate = null
                        result.success("HCE emulation stopped")
                    } catch (e: Exception) {
                        result.error("HCE_ERROR", "Failed to stop HCE emulation: ${e.message}", null)
                    }
                }
                
                "getPlatformVersion" -> {
                    result.success("Android ${android.os.Build.VERSION.RELEASE}")
                }
                
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
