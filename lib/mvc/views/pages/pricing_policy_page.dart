import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PricingPolicyPage extends StatelessWidget {
  const PricingPolicyPage({super.key});

  final List<Map<String, String>> packages = const [
    {
      "name": "বেসিক",
      "price": "৳১০০",
      "credits": "১০ ক্রেডিট",
      "features": "১০ টি গরুর ওজন পরিমাপ",
    },
    {
      "name": "প্রিমিয়াম",
      "price": "৳৩০০",
      "credits": "৫০ ক্রেডিট",
      "features": "৫০ টি গরুর ওজন পরিমাপ",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'মূল্য নির্ধারণ নীতি',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 1, 104, 51),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Card(
                color: Colors.green[50],
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.only(bottom: 16),
                child: const ListTile(
                  leading: Icon(
                    Icons.card_giftcard,
                    color: Colors.green,
                    size: 32,
                  ),
                  title: Text(
                    'সাইন আপ করার পর প্রথম ২০ ক্রেডিট ফ্রি!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 1, 104, 51),
                      fontSize: 22,
                    ),
                  ),
                  subtitle: Text(
                    'নতুন ব্যবহারকারীরা অ্যাকাউন্ট খোলার পর ২০ ক্রেডিট বিনামূল্যে পাবেন।',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Package list without Expanded
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: packages.length,
                itemBuilder: (context, index) {
                  final pkg = packages[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Text(
                            pkg["credits"] ?? "",
                            style: const TextStyle(
                              color: Color.fromARGB(255, 1, 104, 51),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        title: Text(
                          '${pkg["name"]} প্যাকেজ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color.fromARGB(255, 1, 104, 51),
                          ),
                        ),
                        subtitle: Text(
                          pkg["features"] ?? "",
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: Text(
                          pkg["price"] ?? "",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () {
                  // Go back to HomeScreen but with tabIndex = 1 (Credits tab)
                  Get.offAllNamed('/home', arguments: {'tabIndex': 1});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 1, 104, 51),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Packages(প্যাকেজ)',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'আপনার প্রয়োজন অনুযায়ী প্যাকেজ নির্বাচন করুন',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Image.asset('assets/pranisheba-tech-logo.png', height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
