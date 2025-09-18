import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ArucoMarkerDownloadPage extends StatefulWidget {
  const ArucoMarkerDownloadPage({Key? key}) : super(key: key);

  @override
  State<ArucoMarkerDownloadPage> createState() => _ArucoMarkerDownloadPageState();
}

class _ArucoMarkerDownloadPageState extends State<ArucoMarkerDownloadPage> {
  static const String _assetPath = 'assets/pranisheba-aruco-marker.pdf';
  String? _tempPath; // cached temp file path

  Future<File> _writeToTemp(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Aruco_Marker.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<Uint8List> _loadAsset() async {
    final data = await rootBundle.load(_assetPath);
    return data.buffer.asUint8List();
  }

  Future<File> _ensureTempFile() async {
    if (_tempPath != null && await File(_tempPath!).exists()) {
      return File(_tempPath!);
    }
    final bytes = await _loadAsset();
    final f = await _writeToTemp(bytes);
    _tempPath = f.path;
    return f;
  }

  Future<void> _open() async {
    final f = await _ensureTempFile();
    await OpenFilex.open(f.path); // opens with user's PDF viewer
  }

  Future<void> _share() async {
    final f = await _ensureTempFile();
    await Share.shareXFiles(
      [XFile(f.path, mimeType: 'application/pdf', name: 'Aruco_Marker.pdf')],
      text: 'ArUco Marker (print at 100% scale)',
    );
  }

  Future<void> _print() async {
    final bytes = await _loadAsset();
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Download ArUco Marker',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            ),
          ),
        backgroundColor: const Color.fromARGB(255, 1, 104, 51),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Image.asset('assets/aruco-marker.jpg', height: 220),
            const SizedBox(height: 50),
            Text(
              'Print this ArUco marker at 100% scale (no “fit to page”). '
              'Place it flat and fully visible in the photo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.4,
                fontWeight: FontWeight.w500,
                ),
            ),
            const SizedBox(height: 50),

            //* Big buttons
            _ActionButton(
              icon: Icons.open_in_new,
              label: 'Open',
              onPressed: _open,
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.share,
              label: 'Share / Save',
              onPressed: _share,
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.print,
              label: 'Print',
              onPressed: _print,
            ),

            const Spacer(),

            // Tiny preview hint
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.picture_as_pdf),
                SizedBox(width: 8),
                Text('File: pranisheba-aruco-marker.pdf'),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 1, 104, 51),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}
