import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String _errorMessage = '';
  File? _image;

  Future<void> _register() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Kullanıcının profil fotoğrafını Firebase Storage'a yükleyin
      String? imageUrl;
      if (_image != null) {
        // Kullanıcının UID'sini dosya adı olarak kullanarak bir referans oluşturun
        String fileName = userCredential.user!.uid + '.jpg';
        final ref =
            FirebaseStorage.instance.ref().child('profile_images/$fileName');

        // Dosyayı yükleyin
        await ref.putFile(_image!);

        // Dosyanın URL'sini alın
        imageUrl = await ref.getDownloadURL();
      }

      // Kullanıcının adını Firebase Authentication kullanıcısına güncelleyin
      await FirebaseAuth.instance.currentUser!
          .updateDisplayName(_nameController.text.trim());

      // Kullanıcının fotoğrafını Firebase Authentication kullanıcısına güncelleyin
      await FirebaseAuth.instance.currentUser!.updatePhotoURL(imageUrl ?? '');

      // Firestore'a kullanıcı bilgilerini ekleyin
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': userCredential.user!.email,
        'name': _nameController.text.trim(),
        'profileImageUrl': imageUrl ?? '',
        'role': 'user',
        // Diğer kullanıcı bilgilerini buraya ekleyin
      });

      // Kayıt başarılı ise kullanıcıyı ana sayfaya yönlendirin veya istediğiniz bir sayfaya yönlendirin
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'invalid-email':
            _errorMessage = 'Geçersiz e-posta adresi.';
            break;
          case 'email-already-in-use':
            _errorMessage = 'Bu e-posta adresi zaten kullanımda.';
            break;
          case 'weak-password':
            _errorMessage = 'Şifre zayıf. Daha güçlü bir şifre seçin.';
            break;
          default:
            _errorMessage = 'Kayıt olma işlemi başarısız oldu.';
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("lib/assets/images/arkaplan.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 5,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: Text(
                            'Kayıt Ol',
                            style: TextStyle(fontSize: 30),
                          ),
                        ),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'E-posta',
                          ),
                        ),
                        TextField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Şifre',
                          ),
                          obscureText: true,
                        ),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'İsim',
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: _pickImage,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_camera),
                              SizedBox(
                                width: 10,
                              ),
                              Text('Profil Fotoğrafı Seç'),
                            ],
                          ),
                        ),
                        if (_image != null)
                          SizedBox(height: 100, child: Image.file(_image!)),
                        ElevatedButton(
                          onPressed: _register,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add),
                              SizedBox(
                                width: 10,
                              ),
                              Text('Kayıt Ol'),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pushReplacementNamed(context, '/'),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back),
                              SizedBox(
                                width: 10,
                              ),
                              Text('Geri Dön'),
                            ],
                          ),
                        ),
                        if (_errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
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
