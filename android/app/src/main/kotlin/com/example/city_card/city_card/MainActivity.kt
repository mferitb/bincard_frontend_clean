package com.example.city_card.city_card

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import android.os.Bundle
import android.nfc.NfcAdapter
import android.nfc.NfcManager
import android.app.PendingIntent
import android.content.Intent

class MainActivity : FlutterFragmentActivity() {
    private var nfcAdapter: NfcAdapter? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // NFC adaptörünü al
        val nfcManager = getSystemService(NFC_SERVICE) as NfcManager
        nfcAdapter = nfcManager.defaultAdapter
    }
    
    override fun onResume() {
        super.onResume()
        
        // NFC varsa, foreground dispatch'i etkinleştir
        nfcAdapter?.let {
            val intent = Intent(this, javaClass).apply {
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
            val pendingIntent = PendingIntent.getActivity(
                this, 0, intent, PendingIntent.FLAG_MUTABLE
            )
            it.enableForegroundDispatch(this, pendingIntent, null, null)
        }
    }
    
    override fun onPause() {
        super.onPause()
        
        // Foreground dispatch'i devre dışı bırak
        nfcAdapter?.disableForegroundDispatch(this)
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
    }
}
