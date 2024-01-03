// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:siri/boxes.dart';
import 'package:siri/chat.dart';
import 'package:siri/pages/history_list.dart';
import 'package:siri/pages/widgets/animated_icon.dart';
import 'package:siri_wave/siri_wave.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:rive/rive.dart';

class VoiceChatPage extends StatefulWidget {
  const VoiceChatPage({Key? key}) : super(key: key);

  @override
  _VoiceChatPageState createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage> {
  String _task = '';
  bool _isLoading = false;
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  FlutterTts flutterTts = FlutterTts();
  bool _isSpeaking = false;

  String liveText = '';

  @override
  void initState() {
    super.initState();
    initSpeechRecognizer();
  }

  Future<void> initSpeechRecognizer() async {
    try {
      if (await _speech.initialize(
        onStatus: _statusListener,
        onError: _errorListener,
        debugLogging: true,
      )) {
        print("Speech recognition initialized successfully");
      } else {
        print("Speech recognition failed to initialize");
      }
      setState(() {});
    } catch (e) {
      var status = await Permission.microphone.request();
      if (status.isDenied) {
        print("Access Denied");
        // ignore: use_build_context_synchronously
        showAlertDialog(context);
      } else {
        print("Access Granted");
      }
    }
  }

  //alart dialogbox
  showAlertDialog(context) => showCupertinoDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: const Text('Permission Denied'),
          content: const Text('Allow access to microphone'),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => openAppSettings(),
              child: const Text('Settings'),
            ),
          ],
        ),
      );

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
    setState(() {
      _speech.stop();
      _isListening = false;
    });
  }

  void _resultListener(SpeechRecognitionResult result) {
    if (result.finalResult) {
      final recognizedText = result.recognizedWords;
      print('Final result: $recognizedText');

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
      setState(() {
        liveText = result.recognizedWords.toString();
      });
    }
  }

  Future<void> fetchTaskWithPrompt(String prompt) async {
    setState(() {
      _isLoading = true;
    });

    try {
      var apiKey = "API_KEY";
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

              setState(() {
                _task = task;

                _isSpeaking = true;
                addToHistory(prompt, task.toString().trim().replaceAll("*", ""),
                    DateTime.now());
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

  //! add to the hive database
  Future<void> addToHistory(String query, String chat, DateTime time) async {
    boxChats.put('key_${query.length > 50 ? query.substring(0, 50) : query}',
        Chat(query: query, chat: chat, time: time));
  }

  @override
  void dispose() {
    super.dispose();
    _speech.stop();
    flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Padding(
            padding: MediaQuery.of(context).size.width > 600
                ? const EdgeInsets.symmetric(horizontal: 150, vertical: 10)
                : const EdgeInsets.all(16.0),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      height: 120,
                      width: 120,
                      child: RiveAnimation.asset(
                        'assets/loadingdots.riv',
                      ),
                    )
                  : GestureDetector(
                      onLongPress: () {
                        startListening();
                      },
                      onLongPressUp: () {
                        setState(() {
                          liveText = '';
                        });
                        stopListening();
                      },
                      child: _isSpeaking
                          ? SingleChildScrollView(
                              child: Padding(
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
                                        cursor: ' 😀',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : _isListening
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Text(
                                        liveText,
                                        style: TextStyle(
                                          fontSize: 20.0,
                                          color: Colors.white.withOpacity(0.3),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SiriWaveform.ios9(),
                                  ],
                                )
                              : SizedBox(
                                  // width: 250.0,
                                  child: DefaultTextStyle(
                                    style: TextStyle(
                                      fontSize: 32.0,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFE5E5E5)
                                          .withOpacity(0.4),
                                    ),
                                    child: AnimatedTextKit(
                                      repeatForever: true,
                                      animatedTexts: [
                                        FadeAnimatedText('use IT!'),
                                        FadeAnimatedText('use it RIGHT!!'),
                                        FadeAnimatedText('use it RIGHT NOW!!!'),
                                      ],
                                    ),
                                  ),
                                ),
                    ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ChatHistory()));
                },
                icon: Icon(
                  Icons.history,
                  color: Colors.white.withOpacity(0.4),
                )),
          ),
          Positioned(
              bottom: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.chat_bubble,
                      color: Colors.white.withOpacity(0.4),
                    )),
              )),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: GestureDetector(
              onLongPress: () {
                startListening();
              },
              onLongPressUp: () {
                setState(() {
                  liveText = '';
                });
                stopListening();
              },
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: _isSpeaking
                    ? IconButton(
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
                        ),
                      )
                    : AnimatedMicIcon(isListening: _isListening),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
