import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'dart:async';
import 'services/notification_service.dart';
import 'dart:developer'; // Optional: for better logging

// Initialize Facebook App Events
final facebookAppEvents = FacebookAppEvents();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();


  // Initialize notification service
  await NotificationService().initialize();

  // Log app launch event
  try {
    await facebookAppEvents.logEvent(
      name: 'fb_mobile_app_launched',
      parameters: {'time': DateTime.now().toIso8601String()},
    );
    print('Facebook event logged successfully.');
    // Or use:
    log('Facebook event logged successfully.');
  } catch (error, stackTrace) {
    print('Error logging Facebook event: $error');
    // Or use:
    log('Error logging Facebook event', error: error, stackTrace: stackTrace);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

// SplashScreen widget
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay for splash screen before navigating to the WebView page
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WebViewContainer()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png', // Your splash logo
              width: 150,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(), // Optional loading indicator
          ],
        ),
      ),
    );
  }
}

class WebViewContainer extends StatefulWidget {
  const WebViewContainer({super.key});

  @override
  State<WebViewContainer> createState() => _WebViewContainerState();
}

class _WebViewContainerState extends State<WebViewContainer> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  late StreamSubscription _urlSubscription;

  @override
  void initState() {
    super.initState();

    // Subscribe to URL changes from notifications
    _urlSubscription = NotificationService.urlStream.listen((url) {
      if (url.isNotEmpty) {
        _controller.loadRequest(Uri.parse(url));
      }
    });
    // Set the app to full screen mode by hiding system UI
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (url) {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
              },
              onPageFinished: (url) async {
                setState(() {
                  _isLoading = false;
                  _hasError = false;
                });
              },
              onWebResourceError: (error) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                });
              },
            ),
          )
          ..loadRequest(Uri.parse("https://algeriabeauty.shop/"));
  }

  Future<void> _reloadPage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _controller.reload();
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return Future.value(false); // Prevents default back button behavior
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SplashScreen(),
        ), // Navigate back to splash screen
      );
      return Future.value(true); // Allows exiting the app when on splash screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Handles the back button press
      child: Scaffold(
        appBar: null, // No AppBar, for full-screen experience
        body: Padding(
          padding: const EdgeInsets.only(top: 30), // 30px margin on top
          child: Stack(
            children: [
              // WebView inside Pull-to-Refresh
              if (!_hasError)
                RefreshIndicator(
                  onRefresh: _reloadPage,
                  child: WebViewWidget(controller: _controller),
                ),

              // Loading screen with logo
              if (_isLoading)
                Center(
                  child: Container(
                    color: Colors.white,
                    width: double.infinity, // Full width for loader
                    height: double.infinity, // Full height for loader
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo.png', // Your logo
                          width: 150,
                        ),
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(),
                      ],
                    ),
                  ),
                ),

              // Error message when WebView fails to load
              if (_hasError)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 80, color: Colors.red),
                      const SizedBox(height: 10),
                      const Text(
                        "Connection Error",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Please check your internet connection and try again.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _reloadPage,
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlSubscription.cancel();
    super.dispose();
  }
}
