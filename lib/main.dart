import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewPage(),
    );
  }
}
class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    // ✅ Step 1: Create the controller first
    final controller = WebViewController();

    // ✅ Step 2: Configure its behavior
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) async {
            // ✅ Try to autoplay video when the page finishes loading
            await controller.runJavaScript("""
              const v = document.querySelector('video');
              if (v) {
                v.muted = true; // ensure muted for autoplay policy
                v.play().catch(e => console.log('Autoplay blocked:', e));
                if (v.paused) v.controls = true; // fallback: show controls
              }
            """);
          },
        ),
      )
      ..loadRequest(Uri.parse('https://nfctapit.uk'));

    _controller = controller; // ✅ Finally assign it
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
