import 'dart:io';

import 'package:blackhat/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 100,
        title: Text(
          user!.displayName ?? '',
          style: TextStyle(fontSize: 18),
        ),
        leading: UserProfile(),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(1, 1, 20, 1),
            child: IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Genel Duyurular',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: AnnouncementList(),
          ),
          Expanded(
            child: TaskList(),
          ),
        ],
      ),
    );
  }
}

class AnnouncementList extends StatelessWidget {
  const AnnouncementList({super.key});
  final String placeholderImageUrl = 'lib/assets/icon/icon.png';
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('duyurular').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator.adaptive();
        }
        if (snapshot.hasError) {
          return Text('Hata: ${snapshot.error}');
        }
        var announcements = snapshot.data!.docs;

        return ListView.builder(
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            var announcementData =
                announcements[index].data() as Map<String, dynamic>;
            return Card(
              child: Container(
                child: ListTile(
                  title: Text(announcementData['mesaj']),
                  subtitle: Text(DateTime.parse(
                          announcementData['zaman'].toDate().toString())
                      .toString()),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return user != null
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(user.photoURL ?? ''),
                ),
              ],
            ),
          )
        : SizedBox();
  }
}

class TaskList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: currentUserUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Hata: ${snapshot.error}');
        }
        var tasks = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Atanmış Görevler',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            tasks.isEmpty
                ? Text('Atanmış görev bulunamadı.')
                : Card(
                    child: Container(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          var taskData =
                              tasks[index].data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(taskData['taskTitle']),
                            subtitle: Text(taskData['taskContent']),
                            trailing: Text(taskData['deadline']),
                          );
                        },
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ayarlar'),
      ),
      body: SettingsForm(),
    );
  }
}

class SettingsForm extends StatefulWidget {
  @override
  _SettingsFormState createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  File? _image;

  @override
  void initState() {
    super.initState();
    _nameController.text = FirebaseAuth.instance.currentUser!.displayName ?? '';
    _emailController.text = FirebaseAuth.instance.currentUser!.email ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                backgroundColor: Colors.grey,
                radius: 50,
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null
                    ? Icon(Icons.camera_alt, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'İsim'),
            ),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'E-posta'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Şifre'),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _updateUserInfo();
              },
              child: Text('Bilgileri Güncelle'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _signOut(context);
              },
              child: Text('Hesaptan Çıkış Yap'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Oturum kapatma başarılı oldu, ana ekrana yönlendirme vb. işlemler yapılabilir.
      // Örneğin:
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MyApp()),
          (Route<dynamic> route) => false);
    } catch (e) {
      print("Oturum kapatma hatası: $e");
    }
  }

  Future<void> _updateUserInfo() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        if (_image != null) {
          await user.updatePhotoURL(_image!.path);
        }
        if (_nameController.text.isNotEmpty) {
          await user.updateDisplayName(_nameController.text);
        }
        if (_emailController.text.isNotEmpty) {
          await user.updateEmail(_emailController.text);
        }
        if (_passwordController.text.isNotEmpty) {
          await user.updatePassword(_passwordController.text);
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Kullanıcı bilgileri başarıyla güncellendi.'),
          duration: Duration(seconds: 2),
        ));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Bir hata oluştu: $error'),
        duration: Duration(seconds: 2),
      ));
    }
  }
}
