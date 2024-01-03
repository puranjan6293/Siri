import 'package:hive/hive.dart';

part 'chat.g.dart';

@HiveType(typeId: 1)
class Chat {
  Chat({
    required this.query,
    required this.chat,
    required this.time,
  });
  @HiveField(0)
  String query;

  @HiveField(1)
  String chat;

  @HiveField(2)
  DateTime time;
}
