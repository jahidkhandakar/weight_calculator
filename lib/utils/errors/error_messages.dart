import 'dart:ui';

class ErrorMessages {
  static const _en = <String, Map<String, String>>{
    'AUTH_EXPIRED': {
      'title': 'Signed out',
      'message': 'Your session expired. Please sign in again.',
    },
    'NETWORK_ERROR': {
      'title': 'No internet',
      'message': 'Please check your internet connection and try again.',
    },
    'TIMEOUT': {
      'title': 'Taking too long',
      'message': 'The server took too long to respond. Please try again.',
    },
    'SERVER_ERROR': {
      'title': 'Server error',
      'message': 'Our server had a problem. Please try again later.',
    },
    'CLIENT_ERROR': {
      'title': 'Request error',
      'message': 'There was a problem with your request.',
    },
    'NO_CATTLE': {
      'title': 'Invalid photo',
      'message': 'Please upload a cattle photo.',
    },
    'NO_MARKER': {
      'title': 'Marker missing',
      'message': 'Please upload a photo with Aruco Marker.',
    },
    'INVALID_IMAGE': {
      'title': 'Invalid image',
      'message': 'Please upload a clear cattle photo with the Aruco Marker.',
    },
    'UNKNOWN': {
      'title': 'Something went wrong',
      'message': 'Unexpected error occurred. Please try again.',
    },
  };

  static const _bn = <String, Map<String, String>>{
    'AUTH_EXPIRED': {
      'title': 'সাইন আউট হয়েছে',
      'message': 'আপনার সেশন শেষ হয়েছে। দয়া করে আবার সাইন ইন করুন।',
    },
    'NETWORK_ERROR': {
      'title': 'ইন্টারনেট নেই',
      'message': 'ইন্টারনেট সংযোগ চেক করে আবার চেষ্টা করুন।',
    },
    'TIMEOUT': {
      'title': 'সময় বেশি লাগছে',
      'message': 'সার্ভারের উত্তর পেতে দেরি হচ্ছে। আবার চেষ্টা করুন।',
    },
    'SERVER_ERROR': {
      'title': 'সার্ভার সমস্যা',
      'message': 'সার্ভারে সমস্যা হয়েছে। কিছুক্ষণ পরে চেষ্টা করুন।',
    },
    'CLIENT_ERROR': {
      'title': 'রিকোয়েস্টে সমস্যা',
      'message': 'আপনার রিকোয়েস্টে সমস্যা হয়েছে।',
    },
    'NO_CATTLE': {
      'title': 'ভুল ছবি',
      'message': 'দয়া করে গরুর ছবি আপলোড করুন।',
    },
    'NO_MARKER': {
      'title': 'মার্কার নেই',
      'message': 'দয়া করে আরুকো মার্কারসহ ছবি আপলোড করুন।',
    },
    'INVALID_IMAGE': {
      'title': 'ছবি সঠিক নয়',
      'message': 'আরুকো মার্কারসহ পরিষ্কার গরুর ছবি আপলোড করুন।',
    },
    'UNKNOWN': {
      'title': 'কিছু একটা সমস্যা হয়েছে',
      'message': 'অনাকাঙ্ক্ষিত ত্রুটি হয়েছে। আবার চেষ্টা করুন।',
    },
  };

  static Map<String, Map<String, String>> _tableFor(Locale? locale) {
    final lang = (locale?.languageCode ?? 'en').toLowerCase();
    return lang.startsWith('bn') ? _bn : _en;
  }

  static String? titleFor(String code, Locale? locale) {
    return _tableFor(locale)[code]?['title'];
  }

  static String? messageFor(String code, Locale? locale) {
    return _tableFor(locale)[code]?['message'];
  }
}
