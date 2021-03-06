import 'package:cerrado/in_game_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'google_sign_in.dart';

class GameRoom extends StatelessWidget {
  GameRoom({Key? key, required this.title}) : super(key: key);

  final String title;
  final user = FirebaseAuth.instance.currentUser!;

  void _comeInGame({required BuildContext context, String? gameId}) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) {
          return InGame(
            gameId: gameId,
          );
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('games')
            .where('status', isEqualTo: 'open')
            .snapshots(),
        builder: (context,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (snapshot.hasData) {
            final docs = snapshot.data!.docs;
            return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> data = docs[index].data();
                  return ListTile(
                    title: Text(data['name']),
                    subtitle: Text(
                        DateFormat("'Hora: 'HH:mm:ss 'Dia: 'dd-MM-yyyy").format(
                            DateTime.fromMillisecondsSinceEpoch(
                                    (data['created'] as Timestamp)
                                        .millisecondsSinceEpoch)
                                .toLocal())),
                    leading: CircleAvatar(
                      child: IconButton(
                          onPressed: () {
                            _comeInGame(
                                context: context, gameId: docs[index].id);
                          },
                          icon: const Icon(Icons.play_arrow)),
                    ),
                    trailing: Text(
                      data['num_players'].toString(),
                      style: Theme.of(context).textTheme.headline5,
                    ),
                  );
                });
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _comeInGame(context: context);
        },
        child: const Icon(Icons.add),
        tooltip: 'Criar um novo jogo',
      ),
    );
  }
}
