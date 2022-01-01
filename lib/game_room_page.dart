import 'package:cerrado/new_game_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'google_sign_in.dart';

class GameRoom extends StatelessWidget {
  GameRoom({Key? key, required this.title}) : super(key: key);

  final String title;
  final user = FirebaseAuth.instance.currentUser!;

  void _startAddNewGame(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) {
          return const NewGame();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: Padding(
          padding: const EdgeInsets.all(5.0),
          child: CircleAvatar(backgroundImage: NetworkImage(user.photoURL!)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Provider.of<GoogleSignInProvider>(context, listen: false)
                  .googleLogout();
            },
          ),
        ],
      ),
      body: Center(
          child: Column(
        children: [
          Text(user.displayName!),
          Text(user.email!),
        ],
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _startAddNewGame(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
