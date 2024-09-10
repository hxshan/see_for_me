import 'package:flutter_tts/flutter_tts.dart';
import 'package:see_for_me/data/node.dart';

FlutterTts flutterTts = FlutterTts();

enum Direction { up, down, left, right }

Future<void> speak(String text) async {
  await flutterTts.setLanguage("en-US");
  await flutterTts.setPitch(1);
  await flutterTts.speak(text);
}

Future<void> narratePath(List<Node> path) async {
  // Assume you start by facing "up" (North)
  Direction currentFacing = Direction.up;

  for (int i = 0; i < path.length - 1; i++) {
    Node current = path[i];
    Node next = path[i + 1];

    Direction nextMove = _getDirection(current, next);
    String narration = _getNarration(currentFacing, nextMove);
    currentFacing = nextMove; // Update facing direction for next iteration

    // Speak the narration
    await speak(narration);
    // Wait for the current narration to finish
    await flutterTts.awaitSpeakCompletion(true);
  }
  await speak("You have arrived at your destination");
  // Wait for the current narration to finish
  await flutterTts.awaitSpeakCompletion(true);
}

Direction _getDirection(Node current, Node next) {
  // Determine which direction the next step is
  if (next.tile!.x < current.tile!.x) {
    return Direction.up; // Moving "up" (North)
  } else if (next.tile!.x > current.tile!.x) {
    return Direction.down; // Moving "down" (South)
  } else if (next.tile!.y < current.tile!.y) {
    return Direction.left; // Moving "left" (West)
  } else {
    return Direction.right; // Moving "right" (East)
  }
}

String _getNarration(Direction currentFacing, Direction nextMove) {
  if (currentFacing == nextMove) {
    return "Proceed one step forward";
  }

  switch (currentFacing) {
    case Direction.up:
      return _narrateFromUp(nextMove);
    case Direction.down:
      return _narrateFromDown(nextMove);
    case Direction.left:
      return _narrateFromLeft(nextMove);
    case Direction.right:
      return _narrateFromRight(nextMove);
  }
}

String _narrateFromUp(Direction nextMove) {
  switch (nextMove) {
    case Direction.down:
      return "Turn around 180 degrees, proceed one step forward";
    case Direction.left:
      return "Turn left, proceed one step forward";
    case Direction.right:
      return "Turn right, proceed one step forward";
    default:
      return "Proceed one step forward";
  }
}

String _narrateFromDown(Direction nextMove) {
  switch (nextMove) {
    case Direction.up:
      return "Turn around 180 degrees, proceed one step forward";
    case Direction.left:
      return "Turn right, proceed one step forward"; // From down, left is a right turn
    case Direction.right:
      return "Turn left, proceed one step forward"; // From down, right is a left turn
    default:
      return "Proceed one step forward";
  }
}

String _narrateFromLeft(Direction nextMove) {
  switch (nextMove) {
    case Direction.right:
      return "Turn around 180 degrees, proceed one step forward";
    case Direction.up:
      return "Turn right, proceed one step forward"; // From left, up is a right turn
    case Direction.down:
      return "Turn left, proceed one step forward"; // From left, down is a left turn
    default:
      return "Proceed one step forward";
  }
}

String _narrateFromRight(Direction nextMove) {
  switch (nextMove) {
    case Direction.left:
      return "Turn around 180 degrees, proceed one step forward";
    case Direction.up:
      return "Turn left, proceed one step forward"; // From right, up is a left turn
    case Direction.down:
      return "Turn right, proceed one step forward"; // From right, down is a right turn
    default:
      return "Proceed one step forward";
  }
}
