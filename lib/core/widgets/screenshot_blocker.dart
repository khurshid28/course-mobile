import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScreenshotBlocker extends StatefulWidget {
  final Widget child;
  final bool blockScreenshots;
  final bool blockScreenRecording;

  const ScreenshotBlocker({
    Key? key,
    required this.child,
    this.blockScreenshots = true,
    this.blockScreenRecording = true,
  }) : super(key: key);

  @override
  State<ScreenshotBlocker> createState() => _ScreenshotBlockerState();
}

class _ScreenshotBlockerState extends State<ScreenshotBlocker>
    with WidgetsBindingObserver {
  static const platform = MethodChannel('com.course.app/security');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.blockScreenshots || widget.blockScreenRecording) {
      _enableSecurityMeasures();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disableSecurityMeasures();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // iOS'da screenshot olinganda bu chaqiriladi
    if (widget.blockScreenshots) {
      _onScreenshotAttempt();
    }
  }

  Future<void> _enableSecurityMeasures() async {
    try {
      // Android FLAG_SECURE
      await platform.invokeMethod('enableSecureScreen');
    } catch (e) {
      print('Error enabling security: $e');
    }
  }

  Future<void> _disableSecurityMeasures() async {
    try {
      await platform.invokeMethod('disableSecureScreen');
    } catch (e) {
      print('Error disabling security: $e');
    }
  }

  void _onScreenshotAttempt() {
    // Screenshot aniqlansa
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Ogohlantirish'),
        content: const Text(
          'Screenshot olish taqiqlangan! Test davomida screenshot olish mumkin emas.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Native code (Android) - MainActivity.kt uchun
/*
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.course.app/security"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enableSecureScreen" -> {
                    window.setFlags(
                        WindowManager.LayoutParams.FLAG_SECURE,
                        WindowManager.LayoutParams.FLAG_SECURE
                    )
                    result.success(true)
                }
                "disableSecureScreen" -> {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
*/

// Native code (iOS) - AppDelegate.swift uchun
/*
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let securityChannel = FlutterMethodChannel(name: "com.course.app/security",
                                                   binaryMessenger: controller.binaryMessenger)
        
        securityChannel.setMethodCallHandler({ [weak self]
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            switch call.method {
            case "enableSecureScreen":
                NotificationCenter.default.addObserver(
                    self!,
                    selector: #selector(self!.screenshotTaken),
                    name: UIApplication.userDidTakeScreenshotNotification,
                    object: nil
                )
                result(true)
                
            case "disableSecureScreen":
                NotificationCenter.default.removeObserver(
                    self!,
                    name: UIApplication.userDidTakeScreenshotNotification,
                    object: nil
                )
                result(true)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    @objc func screenshotTaken() {
        print("Screenshot taken - notify Flutter")
    }
}
*/
