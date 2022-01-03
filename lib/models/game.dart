class Game {
  final String name;
  final String uid;

  Game({required this.name, required this.uid});

  @override
  String toString() => "Game<$name:$uid>";
}
