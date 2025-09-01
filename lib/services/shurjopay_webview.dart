import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ShurjoPayWebView extends StatefulWidget {
  final String transactionUrl;
  final String? successUrlContains; // e.g., '/payment/success' or 'status=success'
  final String? failUrlContains;    // e.g., '/payment/fail' or 'status=failed'

  const ShurjoPayWebView({
    super.key,
    required this.transactionUrl,
    this.successUrlContains,
    this.failUrlContains,
  });

  @override
  State<ShurjoPayWebView> createState() => _ShurjoPayWebViewState();
}

class _ShurjoPayWebViewState extends State<ShurjoPayWebView> {
  InAppWebViewController? _controller;
  double _progress = 0;

  bool _matches(String url, String? contains) {
    if (contains == null || contains.isEmpty) return false;
    return url.contains(contains);
  }

  @override
  Widget build(BuildContext context) {
    final initialUrl = WebUri(widget.transactionUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ShurjoPay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller?.reload(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: _progress < 1.0
              ? LinearProgressIndicator(value: _progress)
              : const SizedBox.shrink(),
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: initialUrl),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          transparentBackground: false,
          mediaPlaybackRequiresUserGesture: true,
          useShouldOverrideUrlLoading: true,
        ),
        onWebViewCreated: (controller) => _controller = controller,
        onProgressChanged: (controller, progress) {
          setState(() => _progress = progress / 100);
        },
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final uri = navigationAction.request.url;
          final url = uri?.toString() ?? '';

          if (_matches(url, widget.successUrlContains)) {
            if (context.mounted) Navigator.pop(context, {'status': 'success', 'url': url});
            return NavigationActionPolicy.CANCEL;
          }
          if (_matches(url, widget.failUrlContains)) {
            if (context.mounted) Navigator.pop(context, {'status': 'failed', 'url': url});
            return NavigationActionPolicy.CANCEL;
          }
          return NavigationActionPolicy.ALLOW;
        },
        onLoadError: (controller, url, code, message) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('WebView error ($code): $message')),
            );
          }
        },
      ),
    );
  }
}
