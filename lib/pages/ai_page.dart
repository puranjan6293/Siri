// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:siri_wave/siri_wave.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // ignore: unused_field
  String _task = '';
  bool _isLoading = false;
  // ignore: unused_field
  List<String> _tasks = [];
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  FlutterTts flutterTts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    initSpeechRecognizer();
    // fetchTask();
  }

  Future<void> initSpeechRecognizer() async {
    if (await _speech.initialize(
      onStatus: _statusListener,
      onError: _errorListener,
      debugLogging: true,
    )) {
      print("Speech recognition initialized successfully");
    } else {
      print("Speech recognition failed to initialize");
    }
  }

  void _statusListener(String status) {
    print('Speech recognition status: $status');
  }

  void _errorListener(SpeechRecognitionError error) {
    print('Speech recognition error: ${error.errorMsg}');
  }

  void startListening() {
    if (_speech.isAvailable) {
      _speech.listen(
        onResult: _resultListener,
        listenMode: ListenMode.confirmation,
        partialResults: true,
      );
      setState(() {
        _isListening = true;
        flutterTts.stop();
      });
    } else {
      print('Speech recognition is not available');
    }
  }

  void stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _resultListener(SpeechRecognitionResult result) {
    if (result.finalResult) {
      final recognizedText = result.recognizedWords;
      print('Final result: $recognizedText');
      // fetchTaskWithPrompt(recognizedText);
      fetchTaskWithPrompt(recognizedText).then((_) {
        flutterTts.setCompletionHandler(() {
          setState(() {
            _isSpeaking =
                false; // Set _isSpeaking to false after speech completion
          });
        });
      });
    } else {
      print('Partial result: ${result.recognizedWords}');
    }
  }

  Future<void> fetchTaskWithPrompt(String prompt) async {
    setState(() {
      _isLoading = true;
    });

    try {
      var apiKey = "AIzaSyA3LKzbOutMtS0TqpZMwenwrLLXstpYD0k";
      var url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey';

      var body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.9,
          "topK": 1,
          "topP": 1,
          "maxOutputTokens": 2000,
          "stopSequences": []
        },
      });

      var response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if candidates array and its first element are not null
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];

          // Check if content and parts are not null
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null) {
            final parts = candidate['content']['parts'];

            // Check if the first part and text are not null
            if (parts.isNotEmpty && parts[0]['text'] != null) {
              final task = parts[0]['text'];
              //! split the task into multiple tasks
              final splitTasks = task.split('.');
              setState(() {
                _task = task;
                _tasks = splitTasks;
                _isSpeaking = true;
              });

              // Speak the response using flutter_tts
              await flutterTts
                  .setLanguage('en-US'); // Set language to English (US)
              await flutterTts.setVoice({
                'name': 'en-US-Wavenet-F', // Set voice to female Wavenet
                'locale': 'en-US'
              });
              await flutterTts.setPitch(1.0);
              await flutterTts.setSpeechRate(0.9);
              await flutterTts
                  .speak(task.toString().trim().replaceAll("*", ""));
            } else {
              // Handle the case where text is null
              print('Error: Text is null.');
            }
          } else {
            // Handle the case where content or parts are null
            print('Error: Content or parts are null.');
          }
        } else {
          // Handle the case where candidates array is null or empty
          print('Error: Candidates array is null or empty.');
        }
      } else {
        // Handle the case where the HTTP request was not successful
        print(
            'Error: HTTP request failed with status code ${response.statusCode}');
      }
    } catch (e) {
      // Handle exceptions
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  //! featch task without prompt
  Future<void> fetchTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var apiKey = "AIzaSyA3LKzbOutMtS0TqpZMwenwrLLXstpYD0k";
      var url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey';

      var body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "give only one random task for a student to increase study habits"
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.9,
          "topK": 1,
          "topP": 1,
          "maxOutputTokens": 2048,
          "stopSequences": []
        },
      });

      var response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if candidates array and its first element are not null
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];

          // Check if content and parts are not null
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null) {
            final parts = candidate['content']['parts'];

            // Check if the first part and text are not null
            if (parts.isNotEmpty && parts[0]['text'] != null) {
              final task = parts[0]['text'];
              //! split the task into multiple tasks
              final splitTasks = task.split('.');
              setState(() {
                _task = task;
                _tasks = splitTasks;
              });
            } else {
              // Handle the case where text is null
              print('Error: Text is null.');
            }
          } else {
            // Handle the case where content or parts are null
            print('Error: Content or parts are null.');
          }
        } else {
          // Handle the case where candidates array is null or empty
          print('Error: Candidates array is null or empty.');
        }
      } else {
        // Handle the case where the HTTP request was not successful
        print(
            'Error: HTTP request failed with status code ${response.statusCode}');
      }
    } catch (e) {
      // Handle exceptions
      print('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator(
                  color: Colors.deepPurple,
                )
              : GestureDetector(
                  onLongPress: () {
                    startListening();
                  },
                  onLongPressUp: () {
                    stopListening();
                  },
                  child: _isSpeaking
                      ? SingleChildScrollView(
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: DefaultTextStyle(
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    color: Colors.white.withOpacity(0.3),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  child: AnimatedTextKit(
                                    totalRepeatCount: 1,
                                    animatedTexts: [
                                      TypewriterAnimatedText(
                                        _task,
                                        speed: const Duration(milliseconds: 60),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                  onPressed: () {
                                    flutterTts.stop();
                                    setState(() {
                                      _isSpeaking = false;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.stop,
                                    color: Colors.red.shade300,
                                    size: 40,
                                  ))
                            ],
                          ),
                        )
                      : _isListening
                          ? SiriWaveform.ios9()
                          : const Icon(
                              Icons.mic,
                              size: 40,
                              color: Colors.deepPurple,
                            ),
                ),
        ));
  }
}
