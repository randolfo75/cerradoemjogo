import 'package:cerrado/game_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewGame extends StatefulWidget {
  const NewGame({Key? key}) : super(key: key);

  @override
  State<NewGame> createState() => _NewGameState();
}

class _NewGameState extends State<NewGame> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => GamePage(
                                gameName: GameName.typed,
                                title: _nameController.text,
                              )));
                    }
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
