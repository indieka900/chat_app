import 'dart:async';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:chat_app/constants.dart';
import 'package:chat_app/models.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart';

/// Page to chat with someone.
///
/// Displays chat bubbles as a ListView and TextField to enter new chat.
class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (context) => const ChatPage(),
    );
  }

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final Stream<List<Message>> _messagesStream;
  final Map<String, Profile> _profileCache = {};

  @override
  void initState() {
    final myUserId = supabase.auth.currentUser!.id;
    const otherUserId = '94897175-940c-48a8-988f-2254b7dd4dab';

    //_getMessagesWithIds(myUserId, otherUserId);

    _messagesStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        //.eq('profile_id', otherUserId)
        .order('created_at')
        .map((maps) => maps
            .map((map) => Message.fromMap(
                  map: map,
                  myUserId: myUserId,
                ))
            .toList());
    super.initState();
  }

  Future<void> _loadProfileCache(String profileId) async {
    if (_profileCache[profileId] != null) {
      return;
    }
    final data =
        await supabase.from('profiles').select().eq('id', profileId).single();
    final profile = Profile.fromMap(data);
    setState(() {
      _profileCache[profileId] = profile;
    });
  }

  // Future<List<Message>> _getMessagesWithIds(
  //     String userId1, String userId2) async {
  //   final myUserId = supabase.auth.currentUser!.id;
  //   final filterBuilder = supabase
  //       .from('messages')
  //       .select('*')
  //       .or('profile_id.eq.$myUserId,profile_id.eq.$userId2')
  //       //.and('profile_id.eq.$userId1,profile_id.eq.$userId2')
  //       .order('created_at', ascending: false);

  //   final response = await filterBuilder;
  //   final data = response.data as List<dynamic>;
  //   final messages = data
  //       .map((map) => Message.fromMap(
  //             map: map,
  //             myUserId: myUserId,
  //           ))
  //       .toList();
  //   print(messages.length);
  //   return messages;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.white,
              Color.fromARGB(255, 242, 210, 137),
              Color.fromARGB(255, 235, 207, 116),
              Color.fromARGB(255, 239, 192, 36),
            ],
          ),
        ),
        child: StreamBuilder<List<Message>>(
          stream: _messagesStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final messages = snapshot.data!;
              return Column(
                children: [
                  Expanded(
                    child: messages.isEmpty
                        ? const Center(
                            child: Text('Start your conversation now :)'),
                          )
                        : ListView.builder(
                            reverse: true,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];

                              /// I know it's not good to include code that is not related
                              /// to rendering the widget inside build method, but for
                              /// creating an app quick and dirty, it's fine 😂
                              _loadProfileCache(message.profileId);

                              return _ChatBubble(
                                message: message,
                                profile: _profileCache[message.profileId],
                              );
                            },
                          ),
                  ),
                  const _MessageBar(),
                ],
              );
            } else {
              return preloader;
            }
          },
        ),
      ),
    );
  }
}

/// Set of widget that contains TextField and Button to submit message
class _MessageBar extends StatefulWidget {
  const _MessageBar({
    Key? key,
  }) : super(key: key);

  @override
  State<_MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<_MessageBar> {
  late final TextEditingController _textController;
  bool emojiShowing = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[200],
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        emojiShowing = !emojiShowing;
                      });
                    },
                    icon: Icon(
                      Icons.emoji_emotions,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.text,
                      maxLines: null,
                      autofocus: true,
                      onFieldSubmitted: (value) => _submitMessage(),
                      controller: _textController,
                      //style: TextStyle(fontWeight: FontWeight.w700),
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.all(8),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _submitMessage(),
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              Emoji(
                  emojiShowing: emojiShowing, textController: _textController),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final text = _textController.text;
    final myUserId = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('profiles')
        .select('username')
        .eq('id', myUserId)
        .single();
    final myUsername = data['username'];
    if (text.isEmpty) {
      return;
    }
    _textController.clear();
    try {
      await supabase.from('messages').insert({
        'profile_id': myUserId,
        'content': text,
        'user_name': myUsername,
      });
    } on PostgrestException catch (error) {
      context.showErrorSnackBar(message: error.message);
    } catch (_) {
      context.showErrorSnackBar(message: unexpectedErrorMessage);
    }
  }
}

class Emoji extends StatelessWidget {
  const Emoji({
    super.key,
    required this.emojiShowing,
    required TextEditingController textController,
  }) : _textController = textController;

  final bool emojiShowing;
  final TextEditingController _textController;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !emojiShowing,
      child: SizedBox(
        height: 250,
        child: EmojiPicker(
          textEditingController: _textController,
          config: Config(
            columns: 9,
            emojiSizeMax: 32 *
                (foundation.defaultTargetPlatform == TargetPlatform.iOS
                    ? 1.30
                    : 1.0),
            verticalSpacing: 0,
            horizontalSpacing: 0,
            gridPadding: EdgeInsets.zero,
            initCategory: Category.RECENT,
            bgColor: const Color.fromARGB(255, 235, 207, 116),
            indicatorColor: Colors.blue,
            iconColor: Colors.grey,
            iconColorSelected: Theme.of(context).primaryColor,
            backspaceColor: Colors.blue,
            skinToneDialogBgColor: const Color.fromARGB(255, 235, 207, 116),
            skinToneIndicatorColor: Colors.grey,
            enableSkinTones: true,
            showRecentsTab: true,
            recentsLimit: 28,
            replaceEmojiOnLimitExceed: false,
            noRecents: const Text(
              'No Recents',
              style: TextStyle(fontSize: 20, color: Colors.black26),
              textAlign: TextAlign.center,
            ),
            loadingIndicator: const SizedBox.shrink(),
            tabIndicatorAnimDuration: kTabScrollDuration,
            categoryIcons: const CategoryIcons(),
            buttonMode: ButtonMode.MATERIAL,
            checkPlatformCompatibility: true,
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    Key? key,
    required this.message,
    required this.profile,
  }) : super(key: key);

  final Message message;
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    List<Widget> chatContents = [
      if (!message.isMine)
        CircleAvatar(
          child: profile == null
              ? preloader
              : Text(profile!.username.substring(0, 2).toUpperCase()),
        ),
      const SizedBox(width: 12),
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: message.isMine
                ? Theme.of(context).primaryColor
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(message.content),
        ),
      ),
      const SizedBox(width: 12),
      Text(format(message.createdAt, locale: 'en_short')),
      const SizedBox(width: 60),
    ];
    if (message.isMine) {
      chatContents = chatContents.reversed.toList();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      child: Row(
        mainAxisAlignment:
            message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: chatContents,
      ),
    );
  }
}
