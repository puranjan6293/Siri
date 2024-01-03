// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:typed_data';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rive/rive.dart';
import 'package:siri/pages/ai_page.dart';
import 'package:siri/pages/screens/widgets/chat_input_box.dart';
import 'package:siri/pages/screens/widgets/item_image_view.dart';
import 'package:siri/services/gemini/src/init.dart';
import 'package:siri/services/gemini/src/widgets/gemini_response_type_view.dart';

class SectionTextStreamInput extends StatefulWidget {
  const SectionTextStreamInput({super.key});

  @override
  State<SectionTextStreamInput> createState() => _SectionTextInputStreamState();
}

class _SectionTextInputStreamState extends State<SectionTextStreamInput> {
  final ImagePicker picker = ImagePicker();
  final controller = TextEditingController();
  final gemini = Gemini.instance;
  String? searchedText,
      // result,
      _finishReason;

  List<Uint8List>? images;

  String? get finishReason => _finishReason;

  set finishReason(String? set) {
    if (set != _finishReason) {
      setState(() => _finishReason = set);
    }
  }

  //clear everything when the user clicks on the textfield
  void onTapTextField() {
    setState(() {
      searchedText = null;
      finishReason = null;

      // result = null;
    });
    print("clearing everything");
  }

  //alart dialogbox
  showAlertDialog(context) => showCupertinoDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: const Text('Permission Denied'),
          content: const Text('Allow access to photos'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: MediaQuery.of(context).size.width > 600
            ? const EdgeInsets.symmetric(horizontal: 150, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Column(
          children: [
            Expanded(child: GeminiResponseTypeView(
              builder: (context, child, response, loading) {
                if (loading) {
                  return const SizedBox(
                    height: 100,
                    width: 100,
                    child: RiveAnimation.asset(
                      'assets/loadingdots.riv',
                    ),
                  );
                }

                if (response != null) {
                  return Markdown(
                    data: response,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                      h2: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                      h3: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      h4: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      h5: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      h6: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      p: const TextStyle(
                        fontSize: 15,
                        color: Color(
                          0xFFE5E5E5,
                        ),
                      ),
                      blockquote: const TextStyle(
                          fontSize: 16, fontStyle: FontStyle.italic),
                      code: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Monospace',
                        color: Color(0xFFE5E5E5), // Customize code text color
                        backgroundColor: Colors
                            .transparent, // Customize code background color
                        decoration:
                            TextDecoration.none, // Remove code underline
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                } else {
                  return Center(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE5E5E5).withOpacity(0.4),
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
                  );
                }
              },
            )),

            /// if the returned finishReason isn't STOP
            if (finishReason != null) Text(finishReason!),

            if (images != null)
              Container(
                height: 100,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.centerLeft,
                child: Card(
                  color: Colors.blue.withOpacity(0.02),
                  child: ListView.builder(
                    itemBuilder: (context, index) => ItemImageView(
                      bytes: images!.elementAt(index),
                    ),
                    itemCount: images!.length,
                    scrollDirection: Axis.horizontal,
                  ),
                ),
              ),

            //! imported from local widgets
            ChatInputBox(
              onTextFieldTap: onTapTextField,
              onTapVoiceChat: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const VoiceChatPage()));
              },
              controller: controller,
              onClickCamera: () async {
                if (Theme.of(context).platform == TargetPlatform.iOS) {
                  try {
                    //! Check permission
                    PermissionStatus photosStatus =
                        await Permission.photos.request();

                    if (photosStatus == PermissionStatus.granted) {
                      //! Proceed with image picking
                      picker.pickMultiImage().then((value) async {
                        final imagesBytes = <Uint8List>[];
                        for (final file in value) {
                          imagesBytes.add(await file.readAsBytes());
                        }

                        if (imagesBytes.isNotEmpty) {
                          setState(() {
                            images = imagesBytes;
                          });
                        }
                      });
                    }
                    if (photosStatus == PermissionStatus.denied) {
                      showAlertDialog(context);
                    }
                    if (photosStatus == PermissionStatus.permanentlyDenied) {
                      openAppSettings();
                    }
                  } catch (e) {
                    print("Error: $e");
                  }
                } else {
                  try {
                    //! Check permission
                    PermissionStatus cameraStatus =
                        await Permission.camera.request();

                    if (cameraStatus == PermissionStatus.granted) {
                      //! Proceed with image picking
                      picker.pickMultiImage().then((value) async {
                        final imagesBytes = <Uint8List>[];
                        for (final file in value) {
                          imagesBytes.add(await file.readAsBytes());
                        }

                        if (imagesBytes.isNotEmpty) {
                          setState(() {
                            images = imagesBytes;
                          });
                        }
                      });
                    }
                    if (cameraStatus == PermissionStatus.denied) {
                      showAlertDialog(context);
                    }
                    if (cameraStatus == PermissionStatus.permanentlyDenied) {
                      openAppSettings();
                    }
                  } catch (e) {
                    print("Error: $e");
                  }
                }
              },
              onSend: () {
                if (controller.text.isNotEmpty) {
                  searchedText = controller.text;
                  controller.clear();

                  gemini
                      .streamGenerateContent(searchedText!, images: images)
                      .listen((value) {
                    setState(() {
                      images = null;
                    });
                    // result = (result ?? '') + (value.output ?? '');

                    if (value.finishReason != 'STOP') {
                      finishReason = 'Finish reason is `RECITATION`';
                    }
                  }).onError((e) {
                    log('streamGenerateContent error', error: e);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
