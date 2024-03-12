import 'dart:io';

import 'package:blackhat/main.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AdminPanel extends StatelessWidget {
  final TextEditingController duyuruController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Paneli'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: TextField(
                    controller: duyuruController,
                    decoration: InputDecoration(
                      labelText: 'Duyuru',
                      hintText: 'Duyuru metnini girin...',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _duyuruEkle(context, duyuruController.text);
                  },
                  child: Text('Duyuru Yap'),
                ),
              ],
            ),
          ),
          Text(
            'Kullanıcılar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Expanded(child: UserList()), // Diğer içeriği buraya ekleyin
        ],
      ),
    );
  }

  void _duyuruEkle(BuildContext context, String duyuru) {
    FirebaseFirestore.instance.collection('duyurular').add({
      'mesaj': duyuru,
      'zaman': DateTime.now(),
    }).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Duyuru başarıyla eklendi!'),
        duration: Duration(seconds: 2),
      ));
      duyuruController.clear(); // Metin giriş alanını temizle
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Duyuru eklenirken hata oluştu: $error'),
        duration: Duration(seconds: 2),
      ));
    });
  }
}

class UserList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Hata: ${snapshot.error}'),
          );
        }
        var users = snapshot.data!.docs;
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            var userData = users[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(userData['profileImageUrl']),
              ),
              title: Text(
                userData['name'],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskAssignmentScreen(
                      users[index].id,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class TaskAssignmentScreen extends StatelessWidget {
  final String uid;

  TaskAssignmentScreen(this.uid);

  @override
  Widget build(BuildContext context) {
    TextEditingController titleController = TextEditingController();
    TextEditingController contentController = TextEditingController();
    TextEditingController deadlineController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Text('Kullanıcı bulunamadı');
                }
                var userData = snapshot.data!.data() as Map<String, dynamic>;
                return CircleAvatar(
                  backgroundImage: NetworkImage(userData['profileImageUrl']),
                );
              },
            ),
            SizedBox(width: 8),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Text('Kullanıcı bulunamadı');
                }
                var userData = snapshot.data!.data() as Map<String, dynamic>;
                return Text(
                  userData['name'],
                  style: TextStyle(fontSize: 18),
                );
              },
            ),
            SizedBox(
              height: 16,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Görev Başlığı',
                ),
              ),
              TextField(
                controller: contentController,
                decoration: InputDecoration(
                  labelText: 'Görev İçeriği',
                ),
              ),
              TextField(
                controller: deadlineController,
                decoration: InputDecoration(
                  labelText: 'Son Teslim Tarihi',
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  FirebaseFirestore.instance.collection('tasks').add({
                    'taskTitle': titleController.text,
                    'taskContent': contentController.text,
                    'deadline': deadlineController.text,
                    'assignedTo': uid
                  }).then((value) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Görev başarıyla atandı!'),
                      duration: Duration(seconds: 2),
                    ));
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Görev atama başarısız: $error'),
                      duration: Duration(seconds: 2),
                    ));
                  });
                },
                child: Text('Görev Ata'),
              ),
              SizedBox(height: 32.0),
              Text(
                'En Son Atanan Görevler',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.0),
              Card(
                child: Container(
                  child: TaskList(selectedUserUid: uid),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskList extends StatelessWidget {
  final String selectedUserUid;

  const TaskList({Key? key, required this.selectedUserUid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedTo', isEqualTo: selectedUserUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Hata: ${snapshot.error}');
        }
        var tasks = snapshot.data!.docs;
        return tasks.isEmpty
            ? Text('Seçilen kullanıcıya atanmış görev bulunamadı.')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  var taskData = tasks[index].data() as Map<String, dynamic>;
                  return Dismissible(
                    key: Key(tasks[index].id),
                    background: Container(color: Colors.red),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      FirebaseFirestore.instance
                          .collection('tasks')
                          .doc(tasks[index].id)
                          .delete()
                          .then((value) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Görev başarıyla silindi!'),
                          duration: Duration(seconds: 2),
                        ));
                      }).catchError((error) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Görev silinirken hata oluştu: $error'),
                          duration: Duration(seconds: 2),
                        ));
                      });
                    },
                    child: ListTile(
                      title: Text(taskData['taskTitle']),
                      subtitle: Text(taskData['taskContent']),
                      trailing: Text(taskData['deadline']),
                    ),
                  );
                },
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
}
