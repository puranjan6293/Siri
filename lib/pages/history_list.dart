import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siri/boxes.dart';
import 'package:siri/chat.dart';
import 'package:siri/constants/color_list.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatHistory extends StatefulWidget {
  const ChatHistory({super.key});

  @override
  State<ChatHistory> createState() => _ChatHistoryState();
}

class _ChatHistoryState extends State<ChatHistory> {
  Map<String, List<Chat>> groupedChats = {};

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays == -1) {
      return 'Yesterday';
    } else if (difference.inDays >= 7 && difference.inDays < 14) {
      return 'a week ago';
    } else if (difference.inDays < 0 && difference.inDays >= -6) {
      return '${-difference.inDays} days ago';
    } else if (difference.inDays <= -7 && difference.inDays > -30) {
      return 'a month ago';
    } else if (difference.inDays <= -30 && difference.inDays > -60) {
      return 'two months ago';
    } else if (difference.inDays <= -60 && difference.inDays > -90) {
      return 'three months ago';
    } else if (difference.inDays <= -90 && difference.inDays > -365) {
      final monthsAgo = (-difference.inDays ~/ 30);
      return '$monthsAgo months ago';
    } else {
      return timeago.format(time);
    }
  }

  @override
  void initState() {
    super.initState();
    _groupChatsByDate();
  }

  void _groupChatsByDate() {
    groupedChats.clear();

    for (int i = 0; i < boxChats.length; i++) {
      Chat chat = boxChats.getAt(i);
      String formattedTime = _formatTime(chat.time);

      if (!groupedChats.containsKey(formattedTime)) {
        groupedChats[formattedTime] = [];
      }

      groupedChats[formattedTime]!.add(chat);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color(0xFFE5E5E5)),
        backgroundColor: Colors.black,
        title: const Text('History',
            style: TextStyle(fontSize: 16, color: Color(0xFFE5E5E5))),
      ),
      body: ListView.builder(
        itemCount: groupedChats.length,
        itemBuilder: (BuildContext context, int index) {
          String date = groupedChats.keys.elementAt(index);
          List<Chat> chats = groupedChats[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  date,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE5E5E5)),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: chats.length,
                itemBuilder: (BuildContext context, int index) {
                  Chat chat = chats[index];
                  return Dismissible(
                    key: Key(chat.query),
                    onDismissed: (direction) {
                      setState(() {
                        boxChats.deleteAt(index);
                        Fluttertoast.showToast(
                          msg: "Your chat has been deleted",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.transparent,
                          textColor: const Color(0xFFE5E5E5),
                          fontSize: 10.0,
                        );
                        _groupChatsByDate();
                      });
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors[index],
                        radius: 3,
                      ),
                      title: Text(
                        "${chat.query}?",
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          color: const Color(0xFFE5E5E5),
                        ),
                      ),
                      subtitle: SelectableText(
                        chat.chat,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: const Color(0xFFE5E5E5).withOpacity(0.7),
                        ),
                      ),
                      trailing: Text(
                        timeago.format(chat.time),
                        style: GoogleFonts.roboto(
                          fontSize: 9,
                          color: const Color(0xFFE5E5E5).withOpacity(0.4),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
