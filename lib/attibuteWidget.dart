import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CardAttribute extends StatelessWidget {
  const CardAttribute(
      {Key? key,
      required this.attribute,
      required this.attributeName,
      required this.caption,
      required this.compareFunction})
      : super(key: key);

  final Function compareFunction;
  final DocumentSnapshot<Map<String, dynamic>> attribute;
  final String attributeName;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: TextButton(
        onPressed: () {
          compareFunction(attributeName);
        },
        child: Text("$caption: ${attribute[attributeName]}",
            style: Theme.of(context).textTheme.headline6),
      ),
    );
  }
}
