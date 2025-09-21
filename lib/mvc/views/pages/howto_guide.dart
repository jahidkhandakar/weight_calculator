import 'package:flutter/material.dart';

class HowToGuide extends StatelessWidget {
  final List<String> instructions = [
    "১. গরুটিকে সমতল জায়গায় সঠিকভাবে দাঁড় করিয়ে স্থিতিশীল করুন যেন ছবি তোলা যায়। এখন সাবধানে গরুর পেছনে দাঁড়িয়ে আরুকো (Aruco) মার্কারটি গরুর পিঠের সঙ্গে সমান্তরালভাবে স্থাপন করুন।",
    "২. নিশ্চিত করুন যে মার্কারটি ছবিতে সম্পূর্ণরূপে দৃশ্যমান থাকে এবং সেটি কোনো বস্তু বা হাত দ্বারা আচ্ছাদিত না হয়।",
    "৩. মোবাইলের স্ক্রিনে পুরো গরুটিকে ধরা হয় কিনা তা নিশ্চিত করে ছবি তুলুন যেন ওজন নির্ণয় সঠিকভাবে করা যায়।",
    "৪. নিশ্চিত করুন যেন গরুর পুরো শরীর এবং আরুকো মার্কারটি স্পষ্টভাবে দেখা যায়।",
    "৫. ছবি তোলার পর, নিশ্চিত করুন যে ছবিটি পরিষ্কার এবং ফোকাসে রয়েছে।",
    "৬. ছবিটি তোলার পর, ছবিটি উল্লম্বভাবে (Vertical Image) আপলোড করুন।",
    "৭. ছবির অবস্থান সামঞ্জস্য করতে রোটেট (Rotate) বোতামটি ব্যবহার করুন।",
    "৮. ছবি আপলোড করার সময়, নিশ্চিত করুন যে আপনার ইন্টারনেট সংযোগ স্থিতিশীল এবং দ্রুত।",
    "৯. ছবি আপলোড করার পর, ওজন নির্ণয়ের জন্য কিছু সময় অপেক্ষা করুন।",
    "১০. ওজন নির্ণয়ের ফলাফল পেয়ে গেলে, তা সংরক্ষণ করুন বা প্রয়োজনে শেয়ার করুন।",
    "১১. যদি ফলাফল সন্তোষজনক না হয়, তাহলে পুনরায় ছবি তুলে আপলোড করুন।",
    "১২. সর্বদা গরুর নিরাপত্তা এবং আরামকে গুরুত্ব দিন।"
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
