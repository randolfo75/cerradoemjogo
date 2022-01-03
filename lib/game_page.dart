import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GamePage extends StatefulWidget {
  late final String? gameId;
  final user = FirebaseAuth.instance.currentUser!;

  GamePage({Key? key, required this.gameId}) : super(key: key);

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final collectionRef = FirebaseFirestore.instance.collection('games');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Cerrado em Jogo'),
        ),
        body: Center(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: collectionRef.doc(widget.gameId!).snapshots(),
            builder: (context,
                AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                    snapshot) {
              if (!snapshot.hasData) {
                return const Text('Loading...');
              }
              Map<String, dynamic> game =
                  snapshot.data!.data() as Map<String, dynamic>;
              return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '${game['name']}',
                    ),
                    Text(
                      '${game['num_players']}',
                    ),
                    Text(
                      '${game['status']}',
                    ),
                  ]);
            },
          ),
        ));
  }
}
