import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:matrix/matrix.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      context.read<ChatProvider>().initialize(authProvider.accessToken);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty) {
      context.read<ChatProvider>().sendMessage(_messageController.text.trim());
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.saunaChatTitle),
        actions: [
          if (chatProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (chatProvider.error != null)
            Container(
              color: colorScheme.errorContainer,
              padding: const EdgeInsets.all(8.0),
              width: double.infinity,
              child: SelectableText(
                chatProvider.error!,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
          Expanded(
            child: chatProvider.room == null
                ? Center(child: Text(AppLocalizations.of(context)!.connectingToSauna))
                : _buildTimeline(chatProvider),
          ),
          _buildInputArea(colorScheme),
        ],
      ),
    );
  }

  Widget _buildTimeline(ChatProvider chatProvider) {
    return FutureBuilder<Timeline>(
      future: chatProvider.room!.getTimeline(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(AppLocalizations.of(context)!.errorLoadingTimeline(snapshot.error.toString())));
        }
        final timeline = snapshot.data;
        if (timeline == null) {
          return Center(child: Text(AppLocalizations.of(context)!.noMessagesYet));
        }

        final events = timeline.events.where((e) => e.relationshipEventId == null).toList();

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildMessageTile(event, timeline);
          },
        );
      },
    );
  }

  Widget _buildMessageTile(Event event, Timeline timeline) {
    final isMe = event.senderId == chatProvider.client?.userID;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 12.0, bottom: 2.0),
              child: Text(
                event.senderFromMemoryOrFallback.calcDisplayname(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          Material(
            elevation: 1,
            borderRadius: BorderRadius.circular(12),
            color: isMe ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: LinkifiedText(
                text: event.getDisplayEvent(timeline).body,
                style: TextStyle(
                  color: isMe ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                ),
                linkStyle: TextStyle(
                  color: isMe ? colorScheme.onPrimaryContainer : colorScheme.primary,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2.0, left: 4.0, right: 4.0),
            child: Text(
              '${event.originServerTs.hour}:${event.originServerTs.minute.toString().padLeft(2, "0")}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.typeMessageHint,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            color: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  ChatProvider get chatProvider => context.read<ChatProvider>();
}

class LinkifiedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;

  const LinkifiedText({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
  });

  @override
  Widget build(BuildContext context) {
    final List<InlineSpan> spans = [];
    final RegExp urlRegExp = RegExp(
      r'(https?:\/\/[^\s]+|www\.[^\s]+)',
      caseSensitive: false,
    );

    int start = 0;
    for (final RegExpMatch match in urlRegExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: style,
        ));
      }

      final String urlText = match.group(0)!;
      final String fullUrl = urlText.toLowerCase().startsWith('http') ? urlText : 'https://$urlText';

      spans.add(TextSpan(
        text: urlText,
        style: linkStyle ?? const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final Uri uri = Uri.parse(fullUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
      ));

      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
