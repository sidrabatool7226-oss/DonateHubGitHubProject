import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class JazzCashWebViewScreen extends StatefulWidget {
  final String url;

  const JazzCashWebViewScreen({super.key, required this.url});

  @override
  State<JazzCashWebViewScreen> createState() =>
      _JazzCashWebViewScreenState();
}

class _JazzCashWebViewScreenState
    extends State<JazzCashWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _loading = true);
          },
          onPageFinished: (url) {
            setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            if (request.url.contains("actionpost.php")) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Payment Completed ✔"),
                  backgroundColor: Colors.green,
                ),
              );

              Navigator.pop(context);
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("JazzCash Payment"),
        backgroundColor: Colors.red,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}