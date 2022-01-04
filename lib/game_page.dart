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
  DocumentReference<Map<String, dynamic>>? playerRef;
  CollectionReference<Map<String, dynamic>>? cardsRef;
  DocumentReference<Map<String, dynamic>>? gameRef;
  bool isHost = false;
  String? gameStatus;
  Map<String, dynamic> cardsMap = {};
  List<String> deck = [];
  int numPlayers = 0;
  List<List<String>> decks = [];

  @override
  void initState() {
    playersRef =
        FirebaseFirestore.instance.collection('games/${widget.gameId}/players');
    gameRef = FirebaseFirestore.instance.doc('games/${widget.gameId}');
    cardsRef = FirebaseFirestore.instance.collection('cards');

    gameRef!.get().then((snapshot) {
      if (snapshot.exists) {
        setState(() {
          isHost = widget.user.uid == snapshot['host'];
          gameStatus = snapshot['status'];
        });
      }
    });

    // TODO: Change player id to user id
    playersRef!.doc().set({
      // playersRef!.doc(widget.user.uid).set({

      'name': widget.user.displayName,
      'num_cards': 0,
    });

    gameRef!.update({'num_players': FieldValue.increment(1)});

    playerRef = FirebaseFirestore.instance
        .doc('games/${widget.gameId}/players/${widget.user.uid}');

    // Read cards attributes from Firestore
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

    WriteBatch decksBatch = FirebaseFirestore.instance.batch();
    playersRef!.get().then((QuerySnapshot querySnapshot) {
      numPlayers = querySnapshot.docs.length;
      int numCardsByPlayer = deck.length ~/ numPlayers;
      int index = 0;
      for (var player in querySnapshot.docs) {
        List<String> playerDeck = deck.sublist(numCardsByPlayer * index,
            numCardsByPlayer * index + numCardsByPlayer);
        for (var cardId in playerDeck) {
          DocumentReference<Map<String, dynamic>> cardRef =
              playersRef!.doc(player.id).collection('cards').doc(cardId);
          decksBatch.set(cardRef, cardsMap[cardId]);
          decksBatch.update(player.reference, {'num_cards': numCardsByPlayer});
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
                      trailing: Text(
                        player['num_cards'].toString(),
                        style: Theme.of(context).textTheme.headline5,
                      ),
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
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Visibility(
        child: FloatingActionButton(
          onPressed: () {
            gameRef!.update({
              'status': 'started',
            });

            giveCards();

            setState(() {
              gameStatus = 'started';
            });
          },
          child: const Icon(Icons.play_arrow),
        ),
        visible: isHost && gameStatus == 'open',
      ),
    );
  }
}
