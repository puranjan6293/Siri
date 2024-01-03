import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:siri/boxes.dart';
import 'package:siri/chat.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:siri/pages/screens/gemini_stream.dart';
import 'package:siri/services/gemini/src/init.dart';
import 'firebase_options.dart';

void main() async {
  Gemini.init(apiKey: 'API_KEY', enableDebugging: true);
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(ChatAdapter());
  boxChats = await Hive.openBox<Chat>('ToDoBox');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Siri',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SectionTextStreamInput(),
    );
  }
}
