import 'package:cerrado/game_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InGame extends StatefulWidget {
  InGame({Key? key, this.gameId}) : super(key: key);

  final String? gameId;
  final user = FirebaseAuth.instance.currentUser!;

  @override
  State<InGame> createState() => _InGameState();
}

class _InGameState extends State<InGame> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  CollectionReference games = FirebaseFirestore.instance.collection('games');
  Future<DocumentReference> createGame(String name) {
    return games.add({
      'name': name,
      'status': 'open',
      'created': DateTime.now(),
      'num_players': 0,
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {},
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
            child: Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 10,
              right: 10,
              top: 5),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _nameController,
                  // autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Digite um nome';
                    }
                    if (value.length < 3) {
                      return 'Nome muito pequeno';
                    }
                    return null;
                  },
                  // autofocus: true,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: widget.gameId == null
                        ? 'Nome do Jogo'
                        : 'Nome do Jogador',
                  ),
                ),
              ),
              ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (widget.gameId == null) {
                        createGame(_nameController.text).then((value) {
                          Navigator.of(context)
                              .pushReplacement(MaterialPageRoute(
                                  builder: (_) => GamePage(
                                        gameId: value.id,
                                        isHost: true,
                                      )));
                        }).catchError((error) {
                          debugPrint(
                              'Error creating game: ${error ?? 'unknown'}');
                        });
                      } else {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (_) => GamePage(
                                  gameId: widget.gameId,
                                  isHost: false,
                                )));
                      }
                    }
                  },
                  child: widget.gameId == null
                      ? const Text('Criar jogo')
                      : const Text('Jogar')),
              const Divider(),
              ElevatedButton(
                onPressed: () {
                  if (widget.gameId == null) {
                    createGame(widget.user.displayName!).then((value) {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => GamePage(
                                gameId: value.id,
                                isHost: true,
                              )));
                    }).catchError((error) {
                      debugPrint('Error creating game: ${error ?? 'unknown'}');
                    });
                  } else {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => GamePage(
                              gameId: widget.gameId,
                              isHost: false,
                            )));
                  }
                },
                child: widget.gameId == null
                    ? const Text('Criar jogo com seu nome')
                    : const Text('Jogar com seu nome'),
              ),
            ],
          ),
        )));
  }
}
