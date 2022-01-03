class Player {
  final String uid;
  final String name;

  Player({required this.uid, required this.name});

  @override
  String toString() {
    return name;
  }
}
