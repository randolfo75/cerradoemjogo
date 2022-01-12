import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CardAttribute extends StatelessWidget {
  const CardAttribute(
      {Key? key,
      required this.attribute,
      required this.attributeName,
      required this.caption,
      required this.compareFunction,
      required this.yourTurn})
      : super(key: key);

  final Function compareFunction;
  final DocumentSnapshot<Map<String, dynamic>> attribute;
  final String attributeName;
  final String caption;
  final bool yourTurn;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      child: TextButton(
        onPressed: yourTurn
            ? () {
                compareFunction(attributeName);
              }
            : null,
        child: Text("$caption: ${attribute[attributeName]}",
            style: const TextStyle(
                color: Colors.lightGreenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
      ),
    );
  }
}
