import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();

  bool _speechEnabled = false;
  String wordsSpoken = "";

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void processCommand(result) {
    String response = "";
    // if (result.toString().toLowerCase().contains('hello')) {
    //   response = maze[4][5].walkable.toString();
    // } else {
    //   response = "${result.recognizedWords}";
    // }
    setState(() {
      //wordsSpoken = response;
      wordsSpoken = "${result.recognizedWords}";
    });
  }

  void _onSpeechResult(result) {
    processCommand(result);
  }

  speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(1);
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ignore: prefer_const_constructors
            Text(
              "wordsSpoken:$wordsSpoken",
              // ignore: prefer_const_constructors
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.purple[300],
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.mic, size: 60, color: Colors.black),
                onPressed: _speechToText.isListening
                    ? _stopListening
                    : _startListening,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
