import 'package:flutter/material.dart';

class HowToGuide extends StatelessWidget {
  final List<String> instructions = [
    "১. গরুটিকে সমতল জায়গায় সঠিকভাবে দাঁড় করিয়ে স্থিতিশীল করুন যেন ছবি তোলা যায়। এখন সাবধানে গরুর পেছনে দাঁড়িয়ে আরুকো (Aruco) মার্কারটি গরুর পিঠের সঙ্গে সমান্তরালভাবে স্থাপন করুন।",
    "২. নিশ্চিত করুন যে মার্কারটি ছবিতে সম্পূর্ণরূপে দৃশ্যমান থাকে এবং সেটি কোনো বস্তু বা হাত দ্বারা আচ্ছাদিত না হয়।",
    "৩. মোবাইলের স্ক্রিনে পুরো গরুটিকে ধরা হয় কিনা তা নিশ্চিত করে ছবি তুলুন যেন ওজন নির্ণয় সঠিকভাবে করা যায়।",
    "৪. তোলা ছবিটি Cattle Weight Calculator অ্যাপে আপলোড করুন। এবার চারটি নির্দিষ্ট পয়েন্ট নির্ধারণ করুন — যার মধ্যে দুটি গরুর দৈর্ঘ্য বোঝায় এবং বাকি দুটি গার্দ (girth) নির্দেশ করে।",
    "৫. পয়েন্ট দেওয়ার জন্য + বোতাম চাপুন এবং কোনো পয়েন্ট পরিবর্তন করতে বা পূর্বাবস্থায় ফিরাতে ↶ বোতাম চাপুন।",
    "৬. যখন সব পয়েন্ট সঠিকভাবে দেওয়া হয়ে যাবে, তখন √ বোতাম চাপুন যাতে গরুর আনুমানিক ওজন গণনা করা যায়।",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'গরুর ছবি তোলার নির্দেশিকা',
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
