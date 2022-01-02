import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum GameName { gmail, typed, random }

class GamePage extends StatefulWidget {
  final String? title;
  final GameName gameName;
  final user = FirebaseAuth.instance.currentUser!;

  GamePage({Key? key, required this.gameName, this.title}) : super(key: key);

  String _getName(GameName gameName) {
    switch (gameName) {
      case GameName.gmail:
        return user.displayName!;
      case GameName.typed:
        if (title == null) {
          return user.email!;
        } else {
          return title!;
        }
      case GameName.random:
        return 'Random';
      default:
        return 'Unknown';
    }
  }

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final String gameTitle;

  @override
  void initState() {
    gameTitle = widget._getName(widget.gameName);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jogo: $gameTitle'),
      ),
      body: Center(
        child: Text('Game: ${widget.user.email!}'),
      ),
    );
  }
}
