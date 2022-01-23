import 'dart:async';
import 'dart:math';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cerrado/attibuteWidget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GamePage extends StatefulWidget {
  final String? gameId;
  final user = FirebaseAuth.instance.currentUser!;
  final bool isHost;
  final String? newName;

  GamePage({Key? key, required this.gameId, required this.isHost, this.newName})
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

    firebase_storage.FirebaseStorage fileRef =
        firebase_storage.FirebaseStorage.instance;

    // TODO: Change player id to user id
    // in debug mode allow a user to enter multiple times
    // Add player to game
    playersRef!.add({
      // playersRef!.doc(widget.user.uid).set({
      'name': widget.newName ?? widget.user.displayName,
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
        Map<String, dynamic> gameData = snapshot.data()!;
        if (gameData.containsKey('host') && playerId != null) {
          isHost = gameData['host'] == playerId;
          hostId = gameData['host'];
        }
        turn = gameData['turn'];
        turnPlayersList = gameData['turn_players'].cast<String>();
        numPlayers = gameData['num_players'];
        setState(() {
          gameStatus = gameData['status'];
        });
      }
    });

    // Refresh number of players
    gameRef!.update({'num_players': FieldValue.increment(1)});

    // Read cards attributes from Firestore
    cardsDeckRef!.get().then((QuerySnapshot querySnapshot) {
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> cardData = doc.data() as Map<String, dynamic>;
        cardsMap[doc.id] = cardData;
        fileRef
            .ref('images/${cardData["image_name"]}')
            .getDownloadURL()
            .then((url) {
          cardsMap[doc.id]['image_url'] = url;
        });
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
      playersAttributes[playerId] =
          querySnapshot.docs[0].data()[attributeName].toDouble();
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
      // Just one player left
      if (gameStatus == 'playing' && numPlayers == 1) {
        gameRef!.update({'status': 'over'});
      }
      // One player with all cards
      for (String playerId in turnPlayersList) {
        DocumentSnapshot<Map<String, dynamic>> playerData =
            await playersRef!.doc(playerId).get();
        if (playerData.data()!['num_cards'] == cardsMap.length) {
          gameRef!.update({'status': 'over'});
          break;
        }
      }

      // Next turn

      FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot<Map<String, dynamic>> gameSnapshot =
            await transaction.get(gameRef!);
        int nextTurn = gameSnapshot.data()!['turn'] + 1;
        if (nextTurn >= turnPlayersList.length) {
          nextTurn = 0;
        }
        transaction.update(gameRef!, {'turn': nextTurn});
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
      // numPlayers = querySnapshot.docs.length;
      int numCardsByPlayer = deck.length ~/ numPlayers;
      int index = 0;
      for (var player in querySnapshot.docs) {
        turnPlayersList.add(player.id);
        List<String> playerDeck = deck.sublist(numCardsByPlayer * index,
            numCardsByPlayer * index + numCardsByPlayer);
        int order = 0;

        // Create player deck
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
        'turn_players': turnPlayersList,
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
          _playersArea(),
          _cardArea(),
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

  Widget _cardArea() {
    return Expanded(
        flex: 5,
        child: playerDeckRef != null
            ? StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: playerDeckRef!.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text('Você não possui cartas ainda');
                  }
                  final cards = snapshot.data!.docs;
                  if (cards.isEmpty) {
                    return const Text('Você não possui cartas');
                  }
                  return Stack(children: [
                    Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/card_back.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.topLeft,
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage(
                                  "assets/images/${cards[0]['image_name']}"),
                              opacity: 1.0,
                              fit: BoxFit.contain)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _infoArea(cards[0]),
                          _attributesArea(cards[0]),
                        ],
                      ),
                    ),
                  ]);
                },
              )
            : const Text('Cartas ainda não foram distribuidas'));
  }

  Widget _infoArea(DocumentSnapshot<Map<String, dynamic>> card) {
    return Flexible(
      flex: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card['name'],
                    style: const TextStyle(
                        fontSize: 28.0,
                        color: Colors.lightGreenAccent,
                        fontWeight: FontWeight.normal),
                  ),
                  Text(
                    card['subname'],
                    style: const TextStyle(
                        fontSize: 14,
                        color: Colors.lightGreenAccent,
                        fontWeight: FontWeight.normal),
                  ),
                  Text(
                    card['description'] as String,
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.lightGreenAccent,
                        fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
            color: Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _attributesArea(DocumentSnapshot<Map<String, dynamic>> card) {
    return Flexible(
      flex: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CardAttribute(
                attribute: card,
                attributeName: 'attribute1',
                caption: 'Popularidade',
                compareFunction: _processRound,
                yourTurn: turnPlayersList.isNotEmpty &&
                    turnPlayersList[turn] == playerId,
              ),
              CardAttribute(
                attribute: card,
                attributeName: 'attribute2',
                caption: 'Peso (Kg)',
                compareFunction: _processRound,
                yourTurn: turnPlayersList.isNotEmpty &&
                    turnPlayersList[turn] == playerId,
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CardAttribute(
                attribute: card,
                attributeName: 'attribute3',
                caption: 'Filhotes',
                compareFunction: _processRound,
                yourTurn: turnPlayersList.isNotEmpty &&
                    turnPlayersList[turn] == playerId,
              ),
              CardAttribute(
                attribute: card,
                attributeName: 'attribute4',
                caption: 'Anos de vida',
                compareFunction: _processRound,
                yourTurn: turnPlayersList.isNotEmpty &&
                    turnPlayersList[turn] == playerId,
              ),
            ],
          ),
          CardAttribute(
            attribute: card,
            attributeName: 'attribute5',
            caption: 'Risco de extinção',
            compareFunction: _processRound,
            yourTurn:
                turnPlayersList.isNotEmpty && turnPlayersList[turn] == playerId,
          ),
        ],
      ),
    );
  }

  Widget _playersArea() {
    return Expanded(
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
                          turnPlayersList.isNotEmpty &&
                          turnPlayersList[turn] == players[index].id
                      ? const Text('Vez da rodada!')
                      : null,
                  tileColor: gameStatus == 'playing' &&
                          turnPlayersList.isNotEmpty &&
                          turnPlayersList[turn] == players[index].id
                      ? Theme.of(context).backgroundColor
                      : null,
                  dense: true);
            },
          );
        },
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
