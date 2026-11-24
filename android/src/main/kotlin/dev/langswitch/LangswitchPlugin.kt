package dev.langswitch

import android.app.LocaleManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.LocaleList
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** Provides per-app language switching via the platform channel `dev.langswitch/native`. */
class LangswitchPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "dev.langswitch/native")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getAppLocale" -> result.success(getAppLocale())
            "setAppLocale" -> {
                val tag = call.argument<String?>("tag")
                setAppLocale(tag)
                result.success(null)
            }
            "isSystemSettingSupported" ->
                result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU)
            "openSystemLanguageSettings" ->
                result.success(openSystemLanguageSettings())
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun getAppLocale(): String? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return null
        val manager = appContext.getSystemService(Context.LOCALE_SERVICE) as LocaleManager
        val locales = manager.applicationLocales
        return if (locales.isEmpty) null else locales[0].toLanguageTag()
    }

    private fun setAppLocale(tag: String?) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val manager = appContext.getSystemService(Context.LOCALE_SERVICE) as LocaleManager
        manager.applicationLocales = if (tag.isNullOrEmpty()) {
            LocaleList.getEmptyLocaleList()
        } else {
            LocaleList.forLanguageTags(tag)
        }
    }

    private fun openSystemLanguageSettings(): Boolean {
        return try {
            val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                Intent(Settings.ACTION_APP_LOCALE_SETTINGS).apply {
                    data = Uri.fromParts("package", appContext.packageName, null)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            } else {
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.fromParts("package", appContext.packageName, null)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            }
            appContext.startActivity(intent)
            true
        } catch (@Suppress("TooGenericExceptionCaught") e: Exception) {
            false
        }
    }
}
