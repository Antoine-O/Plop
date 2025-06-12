import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plop_app/core/config/app_config.dart';
import 'package:plop_app/core/models/contact_model.dart';
import 'package:plop_app/core/models/message_model.dart';
import 'package:plop_app/core/services/database_service.dart';
import 'package:plop_app/core/services/websocket_service.dart';

class ContactTile extends StatefulWidget {
  final Contact contact;

  const ContactTile({Key? key, required this.contact}) : super(key: key);

  @override
  _ContactTileState createState() => _ContactTileState();
}

class _ContactTileState extends State<ContactTile>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final WebSocketService _webSocketService = WebSocketService();
  final DatabaseService _databaseService = DatabaseService();
  StreamSubscription? _messageSubscription;
  bool _isMuted = false;

  bool _inCooldown = false;
  Timer? _cooldownTimer;
  late AnimationController _cooldownProgressController;

  @override
  void initState() {
    super.initState();
    _isMuted = widget.contact.isMuted ?? false;
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _cooldownProgressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _messageSubscription = _webSocketService.messageUpdates.listen((update) {
      if (!mounted) return;
      if (update['userId'] == widget.contact.userId) {
        _animationController
            .forward()
            .then((_) => _animationController.reverse());
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageSubscription?.cancel();
    _cooldownTimer?.cancel();
    _cooldownProgressController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    if (_inCooldown) return;
    setState(() => _inCooldown = true);
    _cooldownProgressController.forward(from: 0.0);
    _cooldownTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _inCooldown = false);
      }
    });
  }

  void _sendDefaultMessage() {
    if (_inCooldown) return;
    final String defaultMessage = AppConfig.getDefaultPlopMessage(context);
    _webSocketService.sendMessage(
        type: 'plop',
        to: widget.contact.userId,
        payload: defaultMessage,
        isDefault: true);
    _startCooldown();
  }

  void _handleLongPress() {
    if (_inCooldown) return;
    final List<MessageModel> messages = _databaseService.getAllMessages();
    if (messages.isNotEmpty) {
      _showCustomMessageMenu(messages);
    }
  }

  void _showCustomMessageMenu(List<MessageModel> messages) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          shrinkWrap: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return ListTile(
              title: Text(message.text),
              onTap: () {
                _webSocketService.sendMessage(
                    type: 'plop',
                    to: widget.contact.userId,
                    payload: message.text);
                Navigator.pop(context);
                _startCooldown();
              },
            );
          },
        );
      },
    );
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    widget.contact.isMuted = _isMuted;
    await _databaseService.updateContact(widget.contact);
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    return DateFormat.Hm('fr_FR').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasCustomAlias = widget.contact.alias.isNotEmpty &&
        widget.contact.alias != widget.contact.originalPseudo;
    final String primaryName =
        hasCustomAlias ? widget.contact.alias : widget.contact.originalPseudo;
    final String? secondaryName =
        hasCustomAlias ? widget.contact.originalPseudo : null;

    return AbsorbPointer(
      absorbing: _inCooldown,
      child: Opacity(
        opacity: _inCooldown ? 0.5 : 1.0,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Card(
            color: Color(widget.contact.colorValue),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            elevation: 2,
            child: InkWell(
              // Use InkWell for onTap and onLongPress on the whole card
              onTap: _sendDefaultMessage,
              onLongPress: _handleLongPress,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                // Padding for the content inside the card
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // Align content to the left
                  children: [
                    Row(
                      // First line with CircleAvatar, Names, and Mute Button
                      crossAxisAlignment: CrossAxisAlignment.start,
                      // Align children to the top
                      children: [
                        Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white70,
                              child: Text(primaryName.isNotEmpty
                                  ? primaryName[0].toUpperCase()
                                  : '?'),
                            ),
                            if (_inCooldown)
                              AnimatedBuilder(
                                animation: _cooldownProgressController,
                                builder: (context, child) => Positioned.fill(
                                  child: CircularProgressIndicator(
                                    value: _cooldownProgressController.value,
                                    strokeWidth: 2.0,
                                    color: Colors.white.withAlpha(200),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8.0),
                        // Space between avatar and names
                        Expanded(
                          // Take remaining space for names
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            // Essential to prevent column from taking full height
                            children: [
                              Text(primaryName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              if (secondaryName != null)
                                Text(
                                  "($secondaryName)",
                                  style: TextStyle(
                                      color: Colors.grey.shade900,
                                      fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        Align(
                          alignment: Alignment.topRight,
                          // Ensure the icon stays top-right
                          child: IconButton(
                            icon: Icon(
                                _isMuted ? Icons.volume_off : Icons.volume_up,
                                size: 20,
                                color: _isMuted
                                    ? Colors.red
                                    : Colors.grey.shade900),
                            onPressed: _toggleMute,
                            tooltip: _isMuted
                                ? 'Réactiver le son'
                                : 'Mettre en sourdine',
                            padding: EdgeInsets.zero,
                            // Remove default padding from IconButton
                            constraints:
                                const BoxConstraints(), // Remove default constraints
                          ),
                        ),
                      ],
                    ),
                    if (widget.contact.lastMessage !=
                        null) // Second line for message bubble
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        // Padding between first line and message bubble
                        child: Align(
                          // *** NEW: Align the message bubble to centerRight ***
                          alignment: Alignment.centerRight,
                          child: _buildMessageBubble(context),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Text(
              widget.contact.lastMessage!,
              style: const TextStyle(color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTimestamp(widget.contact.lastMessageTimestamp),
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
