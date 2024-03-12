import 'package:blackhat/firebase_options.dart';
import 'package:blackhat/register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'admin_page.dart'; // Yeni eklediğimiz admin sayfasını import edin.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final String placeholderImageUrl = 'lib/assets/icon/icon.png';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'E-posta ile Giriş',
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) {
          if (FirebaseAuth.instance.currentUser != null) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Image.asset(
                      placeholderImageUrl); // Placeholder fotoğrafı göster
                }
                if (snapshot.hasError) {
                  return Text('Bir hata oluştu: ${snapshot.error}');
                }
                var userData = snapshot.data!.data() as Map<String, dynamic>;
                var role = userData['role'];

                if (role == 'admin') {
                  return AdminPanel();
                } else {
                  return HomePage();
                }
              },
            );
          } else {
            return LoginPage();
          }
        },
        '/home': (context) => HomePage(),
        '/admin': (context) =>
            AdminPanel(), // Admin sayfasını yönlendirme için ekleyin.
        '/register': (context) => RegisterPage(),
      },
    );
  }
}
