import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'admin_page.dart'; // Yeni eklediğimiz admin sayfasını import edin.

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signInWithEmailAndPassword() async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // Başarılı giriş durumunda kullanıcının rolünü kontrol edin.
      if (userCredential.user != null) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        String role = userSnapshot.get('role');
        if (role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      print("Hata: $e");
      // Hata durumunda kullanıcıya uyarı gösterilebilir.
      String errorMessage = _errorMessageInTurkish(e);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Hata"),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Tamam"),
            ),
          ],
        ),
      );
    }
  }

  String _errorMessageInTurkish(dynamic e) {
    String errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Geçersiz e-posta adresi.';
          break;
        case 'user-not-found':
        case 'wrong-password':
          errorMessage = 'E-posta adresi veya şifre yanlış.';
          break;
        case 'user-disabled':
          errorMessage = 'Kullanıcı hesabı devre dışı bırakıldı.';
          break;
        case 'too-many-requests':
          errorMessage =
              'Çok fazla deneme yaptınız. Lütfen daha sonra tekrar deneyin.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Giriş işlemi şu anda devre dışı bırakılmıştır.';
          break;
        case 'network-request-failed':
          errorMessage = 'Ağ hatası. Lütfen bağlantınızı kontrol edin.';
          break;
        default:
          errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';
      }
    }
    return errorMessage;
  }

  @override
  Widget build(BuildContext context) {
    String backgroundImage = "lib/assets/images/arkaplan.jpg";

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImage),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Card(
                elevation: 5,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.asset("lib/assets/icon/icon.png"),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(labelText: 'E-posta'),
                        ),
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(labelText: 'Şifre'),
                          obscureText: true,
                        ),
                        SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: _signInWithEmailAndPassword,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                Colors.black, // Buton üzerindeki yazının rengi
                            padding: EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal:
                                    20), // Buton içeriği etrafındaki boşluk
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    10)), // Butonun kenar yuvarlaklığı
                          ),
                          child: Text('Giriş Yap'),
                        ),
                        SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: () => Navigator.pushReplacementNamed(
                              context, '/register'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor:
                                Colors.black, // Buton üzerindeki yazının rengi
                            padding: EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal:
                                    20), // Buton içeriği etrafındaki boşluk
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    10)), // Butonun kenar yuvarlaklığı
                          ),
                          child: Text('Kayıt Ol'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
