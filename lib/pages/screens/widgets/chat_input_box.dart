import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatInputBox extends StatefulWidget {
  final TextEditingController? controller;
  final VoidCallback? onSend, onClickCamera, onTextFieldTap, onTapVoiceChat;
  const ChatInputBox({
    super.key,
    this.controller,
    this.onSend,
    this.onClickCamera,
    this.onTextFieldTap,
    this.onTapVoiceChat,
  });

  @override
  State<ChatInputBox> createState() => _ChatInputBoxState();
}

class _ChatInputBoxState extends State<ChatInputBox> {
  bool isVoiceChat = true;
  @override
  void dispose() {
    super.dispose();
    widget.controller?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.withOpacity(0.08),
      margin: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.onClickCamera != null)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: IconButton(
                onPressed: widget.onClickCamera,
                color: const Color(0xFFE5E5E5),
                icon: const Icon(Icons.image),
              ),
            ),
          Expanded(
            child: TextField(
              autocorrect: true,
              enableSuggestions: true,
              onChanged: (text) {
                setState(() {
                  isVoiceChat = text.isEmpty;
                });
              },
              onTap: widget.onTextFieldTap,
              controller: widget.controller,
              minLines: 1,
              maxLines: 6,
              cursorColor: Theme.of(context).colorScheme.inversePrimary,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              style: GoogleFonts.roboto(
                fontSize: 17,
                color: const Color(0xFFE5E5E5).withOpacity(0.7),
              ),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                hintText: 'Message',
                hintStyle: TextStyle(
                  color: const Color(0xFFE5E5E5).withOpacity(0.5),
                ),
                border: InputBorder.none,
                fillColor: Colors.blue.withOpacity(0.1),
              ),
              onTapOutside: (event) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: isVoiceChat
                ? IconButton(
                    onPressed: widget.onTapVoiceChat,
                    icon: const Icon(
                      Icons.headphones,
                      color: Color(0xFFE5E5E5),
                    ),
                  )
                : IconButton(
                    onPressed: () {
                      widget.onSend?.call();
                      setState(() {
                        isVoiceChat = true;
                      });
                    },
                    icon: const Icon(
                      Icons.send,
                      color: Color(0xFFE5E5E5),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
