import 'package:cerrado/game_room_page.dart';
import 'package:cerrado/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // TODO: implement offline case
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasData) {
            return GameRoom(title: 'Sala de Jogos');
          } else if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          } else {
            return const LoginPage(title: 'Como podemos te chamar?');
          }
        });
  }
}
