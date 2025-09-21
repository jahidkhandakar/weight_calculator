import 'package:flutter/material.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  final List<Map<String, String>> faqs = const [
    {
      "question": "How do I calculate the weight of my cattle?",
      "answer":
          "Upload a clear side photo of your cattle and the app will estimate the weight using AI.",
    },
    {
      "question": "What image format should I use?",
      "answer":
          "You can use JPG, PNG, or JPEG formats. Make sure the image is not blurry.",
    },
    {
      "question": "Is my data safe?",
      "answer":
          "Yes, your data is securely stored and only used for prediction purposes.",
    },
    {
      "question": "Can I use the app offline?",
      "answer":
          "No, you need an active internet connection to use all features.",
    },
    {
      "question": "How do I reset my password?",
      "answer":
          "Go to the login screen and tap 'Forgot Password' to reset your password.",
    },
    {
      "question": "What if the weight prediction is inaccurate?",
      "answer":
          "Ensure the photo is clear, taken from the side, full cow along with ArUco marker is visible.",
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
          "We accept all major credit/debit cards and mobile banking options.",
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
        backgroundColor: const Color.fromARGB(255, 1, 104, 51),
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
              // Remove Expanded, use Column + List.generate
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
                      dividerColor: Colors.transparent, // Remove black divider
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: Colors.white, // Match card color
                      childrenPadding: const EdgeInsets.only(
                        bottom: 8,
                        left: 16,
                        right: 16,
                      ),
                      title: Text(
                        faq["question"] ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 1, 104, 51),
                        ),
                      ),
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            faq["answer"] ?? "",
                            style: const TextStyle(fontSize: 15),
                          ),
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
}
