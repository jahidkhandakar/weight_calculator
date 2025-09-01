import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const Color brand = Color.fromARGB(255, 1, 104, 51);
  static const String kFallbackVersion = 'v1.0.0'; // update if you want a default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: brand,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/weight-machine.png', height: 180),
              const SizedBox(height: 24),

              const SelectableText(
                '‘Cattle Weight Calculator’ অ্যাপ একটি ছবির মাধ্যমে '
                'গবাদি পশুর আনুমানিক ওজন প্রদান করে।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black87,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 36),
              Text(
                'Design and developed by',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 12),

              Image.asset('assets/apsLogo.ico'),

              const SelectableText(
                'Adorsho PraniSheba LTD',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: brand,
                ),
              ),

              const SizedBox(height: 12),

              const SelectableText(
                'Haque Tower (9th Floor) JA-28/8/D,\nMohakhali C/A',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 36),

              //* Version (dynamic, with fallback)
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snap) {
                  final ver = snap.hasData ? 'v${snap.data!.version}' : kFallbackVersion;
                  return Text(
                    ver,
                    style: const TextStyle(fontSize: 16, color: Colors.black45),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
