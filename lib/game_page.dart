import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GamePage extends StatefulWidget {
  final String? gameId;
  final user = FirebaseAuth.instance.currentUser!;

  GamePage({Key? key, required this.gameId}) : super(key: key);

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final gamesRef = FirebaseFirestore.instance.collection('games');
  CollectionReference<Map<String, dynamic>>? playersRef;
  CollectionReference<Map<String, dynamic>>? cardsRef;
  DocumentReference<Map<String, dynamic>>? gameRef;
  bool? isHost;
  String? gameStatus;
  Map<String, dynamic> cardsMap = {};
  List<String> deck = [];
  int num_players = 0;
  List<List<String>> decks = [];

  @override
  void initState() {
    playersRef =
        FirebaseFirestore.instance.collection('games/${widget.gameId}/players');
    gameRef = FirebaseFirestore.instance.doc('games/${widget.gameId}');
    cardsRef = FirebaseFirestore.instance.collection('cards');

    gameRef!.get().then((snapshot) {
      if (snapshot.exists) {
        isHost = widget.user.uid == snapshot['host'];
        gameStatus = snapshot['status'];
      }
    });

    playersRef!.add({
      'uid': widget.user.uid,
      'name': widget.user.displayName,
    });

    cardsRef!.get().then((QuerySnapshot querySnapshot) {
      for (var doc in querySnapshot.docs) {
        cardsMap[doc.id] = doc.data() as Map<String, dynamic>;
      }
    });

    super.initState();
  }

  void giveCards() {
    // List of cards
    cardsMap.forEach((key, value) {
      deck.add(key);
    });
    deck.shuffle();

    num_players = 0;
    WriteBatch decksBatch = FirebaseFirestore.instance.batch();
    playersRef!.get().then((QuerySnapshot querySnapshot) {
      num_players = querySnapshot.docs.length;
      int numCardsByPlayer = deck.length ~/ num_players;
      int index = 0;
      for (var doc in querySnapshot.docs) {
        List<String> playerDeck = deck.sublist(numCardsByPlayer * index,
            numCardsByPlayer * index + numCardsByPlayer);
        for (var cardId in playerDeck) {
          DocumentReference<Map<String, dynamic>> cardRef =
              playersRef!.doc(doc.id).collection('cards').doc(cardId);
          decksBatch.set(cardRef, cardsMap[cardId]);
        }
      }
      decksBatch.commit();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Cerrado em Jogo'),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: playersRef!.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text('Loading...');
                  }
                  final players = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final player = players[index].data();
                      return ListTile(
                        title: Text(player['name']),
                      );
                    },
                  );
                },
              ),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('Cartas: ${cardsMap.length}'),
                  ElevatedButton(
                    child: const Text('Iniciar'),
                    onPressed: () {
                      debugPrint("${cardsMap.length}");
                      gameRef!.update({
                        'status': 'started',
                      });

                      giveCards();
                    },
                  ),
                  ElevatedButton(
                    child: const Text('Finalizar'),
                    onPressed: () {
                      gameRef!.update({
                        'status': 'ended',
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ));
  }
}
