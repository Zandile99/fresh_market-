import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: "AIzaSyByEGIOlS2f7d2BjMJx-10v9lmo_T7LdC4",
        authDomain: "kwandas-fresh-market.firebaseapp.com",
        projectId: "kwandas-fresh-market",
        storageBucket: "kwandas-fresh-market.firebasestorage.app",
        messagingSenderId: "864354214730",
        appId: "1:864354214730:web:560efd7a98fbb83c73d7b3",
      );
    }

    throw UnsupportedError(
      'Firebase options are not configured for this platform.',
    );
  }
}
