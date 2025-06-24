import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:plop/core/config/app_config.dart';
import 'package:plop/core/models/contact_model.dart';
import 'package:plop/core/models/message_model.dart';
import 'package:plop/core/services/database_service.dart';
import 'package:plop/core/services/websocket_service.dart';
import 'package:plop/l10n/app_localizations.dart'; // IMPORTANT: Importez la classe de localisation

class ContactTile extends StatefulWidget {
  final Contact contact;

  const ContactTile({super.key, required this.contact});

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
  late Contact _contact;
  bool _isMuted = false;

  bool _inCooldown = false;
  Timer? _cooldownTimer;
  late AnimationController _cooldownProgressController;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
    _isMuted = _contact.isMuted ?? false;

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _cooldownProgressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // This listener now correctly reloads state to show incoming messages
    _messageSubscription = _webSocketService.messageUpdates.listen((update) {
      if (!mounted) return;
      if (update['userId'] == _contact.userId) {
        final freshContact = _databaseService.getContact(_contact.userId);
        if (freshContact != null) {
          setState(() {
            _contact = freshContact;
          });
        }
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

  // This function now correctly updates state to show sent messages
  void _sendDefaultMessage() async {
    final String defaultMessage = AppConfig.getDefaultPlopMessage(context);
    _sendCustomMessage(defaultMessage);
  }

  void _sendCustomMessage(String message) async {
    if (_inCooldown) return;


    setState(() {
      _contact.lastMessageSent = message;
      _contact.lastMessageSentStatus = MessageStatus.sending;
      _contact.lastMessageSentTimestamp = DateTime.now();
      _contact.lastMessageSentError = null; // Réinitialise l'erreur précédente
    });

    await _contact.save();
    try {
      _webSocketService.sendMessage(
          type: 'plop',
          to: _contact.userId,
          payload: message,
          isDefault: true);

      _startCooldown();

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() {
          _contact.lastMessageSentStatus = MessageStatus.sent;
        });
        await _contact.save();
      }
    } catch (e) {
      // Si l'envoi échoue, on met à jour l'UI avec le statut "échec"
      if (mounted) {
        setState(() {
          _contact.lastMessageSentStatus = MessageStatus.failed;
          _contact.lastMessageSentError =
              e.toString(); // On stocke l'erreur pour le tooltip
        });
        await _contact.save();
      }
    }
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
                _sendCustomMessage(message.text);
                Navigator.pop(context);
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
    _contact.isMuted = _isMuted;
    await _contact.save();
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    // Use the current locale for date formatting
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.Hm(locale).format(timestamp);
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Get the localization instance
    final bool hasCustomAlias =
        _contact.alias.isNotEmpty && _contact.alias != _contact.originalPseudo;
    final String primaryName =
    hasCustomAlias ? _contact.alias : _contact.originalPseudo;
    final String? secondaryName =
    hasCustomAlias ? _contact.originalPseudo : null;

    return AbsorbPointer(
      absorbing: _inCooldown,
      child: Opacity(
        opacity: _inCooldown ? 0.5 : 1.0,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Card(
            color: Color(_contact.colorValue),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            elevation: 2,
            child: InkWell(
              onTap: _sendDefaultMessage,
              onLongPress: _handleLongPress,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 6.0, 8.0, 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 32.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
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
                            ),
                          ],
                        ),
                        if (_contact.lastMessageSent != null ||
                            _contact.lastMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              children: [
                                if (_contact.lastMessageSent != null)
                                  _buildMessageSentBubble(context),
                                const Spacer(),
                                if (_contact.lastMessage != null)
                                  _buildMessageBubble(context),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right:0,
                    child: IconButton(
                      icon: Icon(
                          _isMuted ? Icons.volume_off : Icons.volume_up,
                          size: 20,
                          color: _isMuted
                              ? Colors.red
                              : Colors.grey.shade900),
                      onPressed: _toggleMute,
                      tooltip: _isMuted
                          ? l10n.unmuteTooltip
                          : l10n.muteTooltip,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildMessageBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _contact.lastMessage!,
            style: const TextStyle(color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
          // const SizedBox(height: 4),
          Text(
            _formatTimestamp(_contact.lastMessageTimestamp),
            style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageSentBubble(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.lightGreen.shade100,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _contact.lastMessageSent!,
            style: const TextStyle(color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),

          if (_contact.lastMessageSentStatus != null)
            _buildStatusIndicator(context, _contact.lastMessageSentStatus!),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context, MessageStatus status) {
    final l10n = AppLocalizations.of(context)!; // Get the localization instance
    IconData icon;
    String text; // Text now comes from l10n
    Color color;

    Widget statusWidget;
    switch (status) {
      case MessageStatus.sending:
        icon = Icons.schedule;
        text = l10n.statusSending;
        color = Colors.grey.shade600;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        text = l10n.statusSent;
        color = Colors.grey.shade600;
        break;
      case MessageStatus.distributed:
        icon = Icons.check_circle;
        text = l10n.statusDistributed;
        color = Colors.blue.shade600;
        break;
      case MessageStatus.acknowledged:
        icon = Icons.check_circle;
        text = l10n.statusAcknowledged;
        color = Colors.green.shade600;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        text = l10n.statusFailed;
        color = Colors.red.shade600;
        break;
    }

    // Le widget de base (icône + timestamp)
    statusWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14.0, color: color),
        const SizedBox(width: 4.0),
        Text(
          _formatTimestamp(_contact.lastMessageSentTimestamp),
          style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
        ),
      ],
    );

    // Si le statut est "échec" et qu'il y a un message d'erreur, on l'englobe dans un Tooltip
    if (status == MessageStatus.failed && _contact.lastMessageSentError != null) {
      return Tooltip(
        message: _contact.lastMessageSentError!,
        child: statusWidget,
      );
    }else{
      return Tooltip(
        message: text,
        child: statusWidget,
      );

    }

    // return statusWidget; // Sinon, on retourne le widget de base
  }
}