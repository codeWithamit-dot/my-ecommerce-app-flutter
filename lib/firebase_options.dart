// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

// ✅ FIXED: Removed the extra space at the end of messagingSenderId
const FirebaseOptions defaultFirebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyDvQJiwmQT3YVUigs4Z2-jbfrvlZe_3FCY",
  appId: "1:419604381970:android:bc6c439c7aa52bca0c73cb",
  messagingSenderId: "419604381970", // No space here
  projectId: "my-ecommerce-app-notifications",
  storageBucket: "my-ecommerce-app-notifications.firebasestorage.app",
);

class DefaultFirebaseOptions {
    static FirebaseOptions get currentPlatform {
        if (kIsWeb) {
            throw UnsupportedError('Web is not supported in this app.');
        }
        switch (defaultTargetPlatform) {
            case TargetPlatform.android:
                return defaultFirebaseOptions;
            case TargetPlatform.iOS:
                return defaultFirebaseOptions; 
            default:
                throw UnsupportedError('This platform is not supported.');
        }
    }
}