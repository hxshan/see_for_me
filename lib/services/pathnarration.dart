import 'package:flutter_tts/flutter_tts.dart';
import 'package:see_for_me/data/node.dart';

import 'Direction.dart';

FlutterTts flutterTts = FlutterTts();

Future<void> speak(String text) async {
  await flutterTts.setLanguage("en-US");
  await flutterTts.setPitch(1);
  await flutterTts.speak(text);
}

Future<void> narratePath(List<Node> path, Direction current) async {
  // Assume you start by facing "north" (North)
  Direction currentFacing = current;
  bool finish = false;

  for (int i = 0; i < path.length - 1; i++) {
    Node current = path[i];
    Node next = path[i + 1];

    Direction nextMove = _getDirection(current, next);
    String narration = _getNarration(currentFacing, nextMove);
    currentFacing = nextMove; // northdate facing direction for next iteration

    // Speak the narrations
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
    return Direction.north; // Moving "north" (North)
  } else if (next.tile!.x > current.tile!.x) {
    return Direction.south; // Moving "south" (South)
  } else if (next.tile!.y < current.tile!.y) {
    return Direction.west; // Moving "west" (West)
  } else {
    return Direction.east; // Moving "east" (East)
  }
}

String _getNarration(Direction currentFacing, Direction nextMove) {
  if (currentFacing == nextMove) {
    return "Proceed 1 step forward";
  }

  switch (currentFacing) {
    case Direction.north:
      return _narrateFromnorth(nextMove);
    case Direction.south:
      return _narrateFromsouth(nextMove);
    case Direction.west:
      return _narrateFromwest(nextMove);
    case Direction.east:
      return _narrateFromeast(nextMove);
  }
}

String _narrateFromnorth(Direction nextMove) {
  switch (nextMove) {
    case Direction.south:
      return "Turn around 180 degrees, proceed 1 step forward";
    case Direction.west:
      return "Turn left, proceed 1 step forward";
    case Direction.east:
      return "Turn right, proceed 1 step forward";
    default:
      return "Proceed 1 step forward";
  }
}

String _narrateFromsouth(Direction nextMove) {
  switch (nextMove) {
    case Direction.north:
      return "Turn around 180 degrees, proceed 1 step forward";
    case Direction.west:
      return "Turn right, proceed 1 step forward"; // From south, west is a east turn
    case Direction.east:
      return "Turn left, proceed 1 step forward"; // From south, east is a west turn
    default:
      return "Proceed 1 step forward";
  }
}

String _narrateFromwest(Direction nextMove) {
  switch (nextMove) {
    case Direction.east:
      return "Turn around 180 degrees, proceed 1 step forward";
    case Direction.north:
      return "Turn right, proceed 1 step forward"; // From west, north is a east turn
    case Direction.south:
      return "Turn left, proceed 1 step forward"; // From west, south is a west turn
    default:
      return "Proceed 1 step forward";
  }
}

String _narrateFromeast(Direction nextMove) {
  switch (nextMove) {
    case Direction.west:
      return "Turn around 180 degrees, proceed 1 step forward";
    case Direction.north:
      return "Turn left, proceed 1 step forward"; // From east, north is a west turn
    case Direction.south:
      return "Turn right, proceed 1 step forward"; // From east, south is a east turn
    default:
      return "Proceed 1 step forward";
  }
}
