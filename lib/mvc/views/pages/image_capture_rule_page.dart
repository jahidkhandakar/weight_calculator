import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';

class ImageCaptureRulePage extends StatefulWidget {
  const ImageCaptureRulePage({super.key});

  @override
  State<ImageCaptureRulePage> createState() => _ImageCaptureRulePageState();
}

class _ImageCaptureRulePageState extends State<ImageCaptureRulePage> {
  late PdfControllerPinch _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openAsset('assets/image_capture_rule.pdf'),
    );
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ছবি তোলার নিয়মাবলী',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 1, 104, 51),
        centerTitle: true,
      ),
      body: PdfViewPinch(
        controller: _pdfController,
        backgroundDecoration: const BoxDecoration(color: Colors.white),
      ),
    );
  }
}
