import 'package:flutter/material.dart';

class ArucoMarker extends StatelessWidget {
  final List<String> instructions = [
    "১. গরুর ওজন গণনার জন্য অবশ্যই আরুকো মার্কারসহ গরুর ছবি তুলতে হবে। ছবিতে যদি মার্কার না থাকে, তাহলে অ্যাপ্লিকেশনটি ওজন নির্ণয় করতে পারবে না এবং একটি ত্রুটি (error) দেখাবে।",
    "২. আরুকো মার্কার ডাউনলোড করুন।",
    "৩. ডাউনলোড করা pranisheba-aruco-marker.pdf ফাইলটি খুলে প্রিন্ট করুন। প্রিন্ট করার সময় নিশ্চিত করুন যে পেপার সাইজ “Letter” সেট করা আছে এবং স্কেল “Actual” বা ১০০% এ সেট করা আছে।",
    "৪. প্রিন্টিং সম্পন্ন হলে নিশ্চিত করুন যে ছবিতে মার্কারের প্রতিটি পাশ ২০ সেন্টিমিটার পরিমাপ করে। এটি সঠিকভাবে ওজন নির্ধারণের জন্য অত্যন্ত গুরুত্বপূর্ণ।",
    "৫. প্রিন্ট করা মার্কারটি হার্ডবোর্ডের উপর আটকে দিন এবং ঠিকমতো কেটে নিন।",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'আরুকো মার্কার কীভাবে প্রিন্ট করবেন',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 1, 104, 51),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: instructions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder:
              (context, index) => Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    instructions[index],
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
