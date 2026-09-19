// File generated with user-provided Firebase configuration
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBveZ0AiSefoGbXMqfu3uSVcg7U-WmshS0',
    appId: '1:412427794699:web:701bec824254f288550a0e',
    messagingSenderId: '412427794699',
    projectId: 'geobuzz-66a07',
    authDomain: 'geobuzz-66a07.firebaseapp.com',
    storageBucket: 'geobuzz-66a07.firebasestorage.app',
    measurementId: 'G-NPC2X01V0N',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBveZ0AiSefoGbXMqfu3uSVcg7U-WmshS0',
    appId: '1:412427794699:web:701bec824254f288550a0e',
    messagingSenderId: '412427794699',
    projectId: 'geobuzz-66a07',
    authDomain: 'geobuzz-66a07.firebaseapp.com',
    storageBucket: 'geobuzz-66a07.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBveZ0AiSefoGbXMqfu3uSVcg7U-WmshS0',
    appId: '1:412427794699:web:701bec824254f288550a0e',
    messagingSenderId: '412427794699',
    projectId: 'geobuzz-66a07',
    authDomain: 'geobuzz-66a07.firebaseapp.com',
    storageBucket: 'geobuzz-66a07.firebasestorage.app',
  );
}
