import 'package:chat_app/constants.dart';
import 'package:flutter/material.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  static Route route() {
    return MaterialPageRoute(builder: (_) => const UserListScreen());
  }

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List _users = [];

  @override
  void initState() {
    _getUsers();
    super.initState();
  }

  void _getUsers() async {
    try {
      final response = await supabase.from('profiles').select();
      setState(() {
        _users = response.cast();
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User List'),
      ),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: const CircleAvatar(
                //backgroundImage: NetworkImage(_users[index].avatarUrl),
                ),
            title: Text(_users[index]['username']),
            subtitle: Text(_users[index]['created_at']),
            onTap: () {
              // Navigate to chat screen with selected user
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => ChatScreen(
              //       currentUser: Superbase.instance.auth.currentUser!,
              //       otherUser: _users[index],
              //     ),
              //   ),
              // );
            },
          );
        },
      ),
    );
  }
}
