import 'dart:async';

import 'package:cerrado/attibuteWidget.dart';
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
  CollectionReference<Map<String, dynamic>>? cardRef;
  DocumentReference<Map<String, dynamic>>? gameRef;
  StreamSubscription? sub;
  bool isHost = false;
  String? gameStatus;
  Map<String, dynamic> cardsMap = {};
  List<String> deck = [];
  int numPlayers = 0;
  List<List<String>> decks = [];
  List<String> turnPlayersList = [];
  int turn = 0;

  @override
  void dispose() {
    if (sub != null) {
      sub!.cancel();
    }
    super.dispose();
  }

  @override
  void initState() {
    playersRef =
        FirebaseFirestore.instance.collection('games/${widget.gameId}/players');
    gameRef = FirebaseFirestore.instance.doc('games/${widget.gameId}');
    cardsRef = FirebaseFirestore.instance.collection('cards');
    cardRef = FirebaseFirestore.instance
        .collection('games/${widget.gameId}/players/${widget.user.uid}/cards');

    // Listen game status and ishost flag
    sub = gameRef!.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          isHost = widget.user.uid == snapshot['host'];
          gameStatus = snapshot['status'];
        });
      }
    });

    // TODO: Change player id to user id
    // in debug mode allow a user to enter multiple times
    // Add player to game
    // playersRef!.doc().set({
    playersRef!.doc(widget.user.uid).set({
      'name': widget.user.displayName,
      'num_cards': 0,
    });

    // Refresh number of players
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

  void _compareAttribute(String attributeName) {
    debugPrint('compareAttribute: $attributeName');
  }

  void giveCards() {
    // Create deck
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
        turnPlayersList.add(player.id);
        List<String> playerDeck = deck.sublist(numCardsByPlayer * index,
            numCardsByPlayer * index + numCardsByPlayer);
        for (var cardId in playerDeck) {
          DocumentReference<Map<String, dynamic>> cardRef =
              playersRef!.doc(player.id).collection('cards').doc(cardId);
          // Include card in player's deck
          decksBatch.set(cardRef, cardsMap[cardId]);
          // Refresh player's number of cards
          decksBatch.update(player.reference, {'num_cards': numCardsByPlayer});
        }
      }

      decksBatch.update(gameRef!, {
        'status': 'playing',
      });

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
            flex: 1,
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
                        subtitle: gameStatus == 'playing' &&
                                turnPlayersList[turn] == players[index].id
                            ? const Text('Sua vez!')
                            : const Text(''),
                        tileColor: gameStatus == 'playing' &&
                                turnPlayersList[turn] == players[index].id
                            ? Theme.of(context).backgroundColor
                            : null,
                        dense: true);
                  },
                );
              },
            ),
          ),
          Expanded(
              flex: 2,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: cardRef!.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text('Loading...');
                  }
                  final cards = snapshot.data!.docs;
                  if (cards.isEmpty) {
                    return const Text('Você não possui cartas');
                  }
                  return Container(
                    alignment: Alignment.bottomLeft,
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                            image:
                                ExactAssetImage('assets/images/card_back.jpg'),
                            opacity: 0.2,
                            fit: BoxFit.cover)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "${cards[0]['name']}",
                          style: Theme.of(context).textTheme.headline4,
                        ),
                        Text(
                          "${cards[0]['subname']}",
                          style: Theme.of(context).textTheme.bodyText1,
                        ),
                        Text(
                          "${cards[0]['description']}",
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        CardAttribute(
                            attribute: cards[0],
                            attributeName: 'atribute1',
                            caption: 'Popularidade',
                            compareFunction: _compareAttribute),
                        CardAttribute(
                            attribute: cards[0],
                            attributeName: 'atribute2',
                            caption: 'Peso (Kg)',
                            compareFunction: _compareAttribute),
                        CardAttribute(
                            attribute: cards[0],
                            attributeName: 'atribute3',
                            caption: 'Filhotes',
                            compareFunction: _compareAttribute),
                        CardAttribute(
                            attribute: cards[0],
                            attributeName: 'atribute4',
                            caption: 'Anos de vida',
                            compareFunction: _compareAttribute),
                        CardAttribute(
                            attribute: cards[0],
                            attributeName: 'atribute5',
                            caption: 'Risco de extinção',
                            compareFunction: _compareAttribute),
                      ],
                    ),
                  );
                },
              )),
        ],
      ),
      floatingActionButton: Visibility(
        child: FloatingActionButton(
          onPressed: () {
            giveCards();
          },
          child: const Icon(Icons.play_arrow),
        ),
        visible: isHost && gameStatus == 'open',
      ),
    );
  }
}
