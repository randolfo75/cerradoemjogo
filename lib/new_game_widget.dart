import 'package:cerrado/game_page.dart';
import 'package:flutter/material.dart';

class NewGame extends StatefulWidget {
  const NewGame({Key? key}) : super(key: key);

  @override
  State<NewGame> createState() => _NewGameState();
}

class _NewGameState extends State<NewGame> {
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
              const TextField(
                // autofocus: true,
                maxLength: 20,
                decoration: InputDecoration(
                  labelText: 'Nome do Jogo',
                ),
              ),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => GamePage(
                              gameName: GameName.typed,
                              title: 'Nome do Jogo',
                            )));
                  },
                  child: const Text('Criar jogo')),
              const Divider(),
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => GamePage(
                              gameName: GameName.gmail,
                            )));
                  },
                  child: const Text('Criar jogo com seu nome')),
            ],
          ),
        )));
  }
}
