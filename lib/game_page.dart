import 'dart:async';
import 'dart:math';

import 'package:cerrado/attibuteWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GamePage extends StatefulWidget {
  final String? gameId;
  final user = FirebaseAuth.instance.currentUser!;
  final bool isHost;

  GamePage({Key? key, required this.gameId, required this.isHost})
      : super(key: key);

  @override
  _GamePageState createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final gamesRef = FirebaseFirestore.instance.collection('games');
  CollectionReference<Map<String, dynamic>>? playersRef;
  DocumentReference<Map<String, dynamic>>? playerRef;
  CollectionReference<Map<String, dynamic>>? cardsDeckRef =
      FirebaseFirestore.instance.collection('cards');
  Query<Map<String, dynamic>>? playerDeckRef;
  DocumentReference<Map<String, dynamic>>? gameRef;
  StreamSubscription? sub;
  bool isHost = false;
  String? playerId;
  String? gameStatus;
  Map<String, dynamic> cardsMap = {};
  List<String> deck = [];
  int numPlayers = 0;
  List<List<String>> decks = [];
  List<String> turnPlayersList = [];
  int turn = 0;
  String hostId = '';

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

    // TODO: Change player id to user id
    // in debug mode allow a user to enter multiple times
    // Add player to game
    playersRef!.add({
      // playersRef!.doc(widget.user.uid).set({
      'name': widget.user.displayName,
      'num_cards': 0,
    }).then((value) {
      playerId = value.id;
      playerDeckRef = FirebaseFirestore.instance
          .collection('games/${widget.gameId}/players/$playerId/cards')
          .orderBy('order', descending: false);
      playerRef = FirebaseFirestore.instance
          .doc('games/${widget.gameId}/players/$playerId');
      if (widget.isHost) {
        gameRef!.update({'host': playerId});
      }
    });

    // Listen game status and ishost flag
    sub = gameRef!.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          if (snapshot.data()!.containsKey('host') && playerId != null) {
            isHost = playerId == snapshot['host'];
            hostId = snapshot['host'];
          }
          gameStatus = snapshot['status'];
        });
      }
    });

    // Refresh number of players
    gameRef!.update({'num_players': FieldValue.increment(1)});

    // Read cards attributes from Firestore
    cardsDeckRef!.get().then((QuerySnapshot querySnapshot) {
      for (var doc in querySnapshot.docs) {
        cardsMap[doc.id] = doc.data() as Map<String, dynamic>;
      }
    });

    super.initState();
  }

  void _processRound(String attributeName) async {
    debugPrint('compareAttribute: $attributeName');

    Map<String, double> playersAttributes = {};
    Map<String, String> playersCardsId = {};

    QuerySnapshot<Map<String, dynamic>> querySnapshot;

    // Get all players cards first card attributes
    for (String playerId in turnPlayersList) {
      Query<Map<String, dynamic>> playerCards = playersRef!
          .doc(playerId)
          .collection('cards')
          .orderBy('order', descending: false);
      querySnapshot = await playerCards.get();
      playersAttributes[playerId] = querySnapshot.docs[0].data()[attributeName];
      playersCardsId[playerId] = querySnapshot.docs[0].id;
    }

    // Max attribute value
    double maxAttribute = playersAttributes.values.reduce(max);
    // Filter players with max attribute value
    List<String> maxAttributePlayers = playersAttributes.keys
        .where((playerId) => playersAttributes[playerId] == maxAttribute)
        .toList();

    if (maxAttributePlayers.length == 1) {
      // Winner
      String winnerId = maxAttributePlayers[0];

      // Update players cards
      List<String> lostCards = [];
      for (String playerId in turnPlayersList) {
        CollectionReference<Map<String, dynamic>> playerCards =
            playersRef!.doc(playerId).collection('cards');
        if (winnerId != playerId) {
          // Losers
          playersRef!
              .doc(playerId)
              .update({'num_cards': FieldValue.increment(-1)});
        } else {
          // Winner
          playersRef!
              .doc(playerId)
              .update({'num_cards': FieldValue.increment(numPlayers - 1)});
        }
        // Annotate to remove cards from players (winner and losers)
        lostCards.add(playersCardsId[playerId] as String);
        // Remove first card
        playerCards.doc(playersCardsId[playerId]).delete();
      }

      CollectionReference<Map<String, dynamic>> playerCards =
          playersRef!.doc(winnerId).collection('cards');
      // Get last card order to add new card in bottom
      querySnapshot =
          await playerCards.orderBy('order', descending: true).get();
      int newOrder = querySnapshot.docs[0].data()['order'] as int;

      // Add cards to winner
      int index = 0;
      for (String cardId in lostCards) {
        index++;
        cardsMap[cardId]['order'] = newOrder + index;
        playerCards.doc(cardId).set(cardsMap[cardId]);
      }

      // Verify if game is over
      if (gameStatus == 'playing' && numPlayers == 1) {
        gameRef!.update({'status': 'over'});
      }
      for (String playerId in turnPlayersList) {
        DocumentSnapshot<Map<String, dynamic>> playerData =
            await playersRef!.doc(playerId).get();
        if (playerData.data()!['num_cards'] == cardsMap.length) {
          gameRef!.update({'status': 'over'});
          break;
        }
      }

      setState(() {
        if (turn < turnPlayersList.length - 1) {
          turn++;
        } else {
          turn = 0;
        }
      });
    } else {
      // Draw
    }
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
        int order = 0;
        for (var cardId in playerDeck) {
          order++;
          DocumentReference<Map<String, dynamic>> cardDeckRef =
              playersRef!.doc(player.id).collection('cards').doc(cardId);
          // Include order in card
          cardsMap[cardId]['order'] = order;
          // Include card in player's deck
          decksBatch.set(cardDeckRef, cardsMap[cardId]);
          // Refresh player's number of cards
          decksBatch.update(player.reference, {'num_cards': numCardsByPlayer});
        }
        index++;
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
            flex: 2,
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
                        title: _playerTitle(player, gameStatus),
                        leading: hostId == players[index].id
                            ? const CircleAvatar(
                                child: Icon(Icons.person),
                              )
                            : null,
                        trailing: Text(
                          player['num_cards'].toString(),
                          style: Theme.of(context).textTheme.headline5,
                        ),
                        subtitle: gameStatus == 'playing' &&
                                turnPlayersList[turn] == players[index].id
                            ? const Text('Vez da rodada!')
                            : null,
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
              flex: 5,
              child: playerDeckRef != null
                  ? StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: playerDeckRef!.snapshots(),
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
                                  image: ExactAssetImage(
                                      'assets/images/card_back.jpg'),
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
                                  compareFunction: _processRound),
                              CardAttribute(
                                  attribute: cards[0],
                                  attributeName: 'atribute2',
                                  caption: 'Peso (Kg)',
                                  compareFunction: _processRound),
                              CardAttribute(
                                  attribute: cards[0],
                                  attributeName: 'atribute3',
                                  caption: 'Filhotes',
                                  compareFunction: _processRound),
                              CardAttribute(
                                  attribute: cards[0],
                                  attributeName: 'atribute4',
                                  caption: 'Anos de vida',
                                  compareFunction: _processRound),
                              CardAttribute(
                                  attribute: cards[0],
                                  attributeName: 'atribute5',
                                  caption: 'Risco de extinção',
                                  compareFunction: _processRound),
                            ],
                          ),
                        );
                      },
                    )
                  : const Text('Loading...')),
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

  Widget _playerTitle(player, gameStatus) {
    if (gameStatus != 'open' && player['num_cards'] == 0) {
      return Text(
        "${player['name']} PERDEU",
        style: Theme.of(context).textTheme.headline5,
      );
    }
    if (gameStatus != 'open' && player['num_cards'] == cardsMap.length) {
      return Text(
        "${player['name']} GANHOU",
        style: Theme.of(context).textTheme.headline5,
      );
    } else {
      return Text(
        "${player['name']}",
        style: Theme.of(context).textTheme.headline6,
      );
    }
  }
}
