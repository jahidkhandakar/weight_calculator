// lib/mvc/views/pages/faq_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  static const Color brand = Color.fromARGB(255, 1, 104, 51);

  final List<Map<String, String>> faqs = const [
    {
      "question": "How do I calculate the weight of my cattle?",
      "answer":
          "Upload a clear side photo of your cattle and the app will estimate the weight using AI.  Ensure the photo is clear, taken from the side, and the full cow along with the ArUco marker is visible. Click Here to see how to capture an image properly",
    },
    {
      "question": "What image format should I use?",
      "answer": "You can use JPG, PNG, or JPEG formats. Make sure the image is not blurry.",
    },
    {
      "question": "Is my data safe?",
      "answer": "Yes, your data is securely stored and only used for prediction purposes.",
    },
    {
      "question": "Can I use the app offline?",
      "answer": "No, you need an active internet connection to use all features.",
    },
    {
      "question": "How do I reset my password?",
      "answer": "Go to the login screen and tap 'Forgot Password' to reset your password.",
    },
    {
      "question": "What if the weight prediction is inaccurate?",
      "answer": "Ensure the photo is clear, taken from the side, full cow along with ArUco marker is visible.",
    },
    {
      "question": "How many cattle can I measure with one credit?",
      "answer": "One credit allows you to measure the weight of one cattle.",
    },
    {
      "question": "Do credits expire?",
      "answer": "No, credits do not expire and can be used anytime.",
    },
    {
      "question": "Can I get a refund for unused credits?",
      "answer":
          "Refunds are not available for unused credits. Please use them before purchasing more.",
    },
    {
      "question": "What payment methods are accepted?",
      "answer":
          "We accept all major credit/debit cards and mobile banking options through shurjoPay and Google Pay",
    },
    {
      "question": "Can I calculate weight from any angle of the photo?",
      "answer":
          "No, weight calculation requires a clear, full side-view photo of the cow with the ArUco marker visible and aligned with the cow's body. The cow must be standing straight, with no obstructions.",
    },
    {
      "question": "Do I need the ArUco marker in the photo?",
      "answer":
          "Yes, the 20×20 cm ArUco marker is mandatory for scaling the image, converting pixels to real-world measurements for accurate weight estimation.",
    },
    {
      "question": "What other factors affect weight estimation?",
      "answer":
          "Proper alignment of the ArUco marker with the back of the cattle and consistent lighting are essential. The model's accuracy depends on clear visibility of key points and the quality of the image.",
    },
    {
      "question": "Can this system be used for all cattle?",
      "answer":
          "The system works for all adult cattle that are standing upright, well-lit, and have a clear view of the ArUco marker. Poor lighting or obstructions may affect accuracy.",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FAQ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: brand,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/faq_banner.png',
                  height: 180,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Find answers to common questions about using the app, cattle weight prediction, and more.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade800,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Cards
              ...List.generate(faqs.length, (index) {
                final faq = faqs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: Colors.white,
                      childrenPadding: const EdgeInsets.only(
                        bottom: 8, left: 16, right: 16,
                      ),
                      title: Text(
                        faq["question"] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: brand,
                        ),
                      ),
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          child: _answerWithLink(faq["answer"] ?? ""),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  /// Turns the literal text "Click Here" into a tappable link that navigates to /image_rules
  Widget _answerWithLink(String text) {
    const linkText = 'Click Here';
    final idx = text.indexOf(linkText);
    if (idx == -1) {
      // No link phrase → plain text
      return Text(text, style: const TextStyle(fontSize: 15));
    }

    final before = text.substring(0, idx);
    final after = text.substring(idx + linkText.length);

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: linkText,
            style: const TextStyle(
              color: brand,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w600,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                // Navigate to your rules page (route must be registered)
                Get.toNamed('/image_rules');
              },
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
