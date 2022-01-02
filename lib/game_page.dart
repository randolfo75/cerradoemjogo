import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  CollectionReference games = FirebaseFirestore.instance.collection('games');

  Future<void> addGame() {
    return games
        .add({
          'name': gameTitle,
          'status': 'open',
          'created': DateTime.now(),
          'num_players': 1,
        })
        .then((value) => debugPrint('Game created: ${value.id}'))
        .catchError((error) => debugPrint('Error creating game: $error'));
  }

  @override
  void initState() {
    gameTitle = widget._getName(widget.gameName);
    addGame();
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
