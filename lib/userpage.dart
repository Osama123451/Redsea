import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('users');
  List<Map<dynamic, dynamic>> _users = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      DatabaseEvent event = await _dbRef.once();
      final data = event.snapshot.value;

      if (data == null) {
        setState(() {
          _users = [];
          _loading = false;
        });
        return;
      }

      // تحويل البيانات إلى قائمة منظمة
      final Map<dynamic, dynamic> usersMap = data as Map<dynamic, dynamic>;
      List<Map<dynamic, dynamic>> loadedUsers = [];

      usersMap.forEach((key, value) {
        if (value is Map) {
          loadedUsers.add({
            'uid': key,
            'firstName': value['firstName'] ?? '',
            'lastName': value['lastName'] ?? '',
            'phone': value['phone'] ?? '',
            'password': value['password'] ?? '',
          });
        }
      });

      setState(() {
        _users = loadedUsers;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('قائمة المستخدمين')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text('حدث خطأ: $_errorMessage'))
          : _users.isEmpty
          ? const Center(child: Text('لا يوجد مستخدمين حالياً'))
          : ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: Text('${user['firstName']} ${user['lastName']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📞 ${user['phone']}'),
                  Text('🔑 ${user['password']}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
