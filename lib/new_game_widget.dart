import 'package:cerrado/game_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NewGame extends StatefulWidget {
  const NewGame(
      {Key? key, required this.name, required this.isHost, this.gameId})
      : super(key: key);

  final String name;
  final bool isHost;
  final String? gameId;

  @override
  State<NewGame> createState() => _NewGameState();
}

class _NewGameState extends State<NewGame> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  CollectionReference games = FirebaseFirestore.instance.collection('games');
  Future<DocumentReference> createGame() {
    return games.add({
      'name': widget.name,
      'status': 'open',
      'created': DateTime.now(),
      'num_players': 1,
    }).catchError((error) {
      debugPrint('Error creating game: ${error ?? 'unknown'}');
      return null;
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
                  decoration: const InputDecoration(
                    labelText: 'Nome do Jogo',
                  ),
                ),
              ),
              ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (widget.isHost) {
                        createGame().then((value) {
                          Navigator.of(context)
                              .pushReplacement(MaterialPageRoute(
                                  builder: (_) => GamePage(
                                        gameId: value.id,
                                      )));
                        });
                      } else {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (_) => GamePage(
                                  gameId: widget.gameId,
                                )));
                      }
                    }
                  },
                  child: const Text('Criar jogo')),
              const Divider(),
              ElevatedButton(
                  onPressed: () {
                    if (widget.isHost) {
                      createGame().then((value) {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (_) => GamePage(
                                  gameId: value.id,
                                )));
                      });
                    } else {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => GamePage(
                                gameId: widget.gameId,
                              )));
                    }
                  },
                  child: const Text('Criar jogo com seu nome')),
            ],
          ),
        )));
  }
}
