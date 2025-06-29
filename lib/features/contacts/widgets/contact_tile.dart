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
    debugPrint(
        '[ContactTile] initState for contact: ${widget.contact.userId} - ${widget.contact.alias}');
    _contact = widget.contact;
    _isMuted = _contact.isMuted ?? false;
    debugPrint(
        '[ContactTile] initState - Initial _isMuted: $_isMuted for contact: ${_contact.userId}');

    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _cooldownProgressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // This listener now correctly reloads state to show incoming messages
    _messageSubscription =
        _webSocketService.messageUpdates.listen((update) async {
          if (!mounted) {
            debugPrint(
                '[ContactTile] _messageSubscription - Not mounted, skipping update for contact: ${_contact.userId}');
            return;
          }
          debugPrint(
              '[ContactTile] _messageSubscription - Received update: $update for contact: ${_contact.userId}');
          if (update['userId'] == _contact.userId) {
            debugPrint(
                '[ContactTile] _messageSubscription - Update matches current contact: ${_contact.userId}');
            final freshContact = _databaseService.getContact(_contact.userId);
            if (freshContact != null) {
              debugPrint(
                  '[ContactTile] _messageSubscription - Fetched fresh contact: ${freshContact.userId} - ${freshContact.lastMessage}');
              setState(() {
                _contact = freshContact;
              });
            } else {
              debugPrint(
                  '[ContactTile] _messageSubscription - Could not fetch fresh contact for: ${_contact.userId}');
            }
            _animationController
                .forward()
                .then((_) => _animationController.reverse());
          }
        });
    debugPrint(
        '[ContactTile] initState completed for contact: ${_contact.userId}');
  }

  @override
  void dispose() {
    debugPrint('[ContactTile] dispose for contact: ${_contact.userId}');
    _animationController.dispose();
    _messageSubscription?.cancel();
    _cooldownTimer?.cancel();
    _cooldownProgressController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    debugPrint(
        '[ContactTile] _startCooldown called for contact: ${_contact.userId}. Current _inCooldown: $_inCooldown');
    if (_inCooldown) {
      debugPrint(
          '[ContactTile] _startCooldown - Already in cooldown for contact: ${_contact.userId}, returning.');
      return;
    }
    setState(() => _inCooldown = true);
    _cooldownProgressController.forward(from: 0.0);
    _cooldownTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        debugPrint(
            '[ContactTile] _startCooldown - Cooldown finished for contact: ${_contact.userId}. Setting _inCooldown to false.');
        setState(() => _inCooldown = false);
      } else {
        debugPrint(
            '[ContactTile] _startCooldown - Cooldown timer finished but widget not mounted for contact: ${_contact.userId}.');
      }
    });
    debugPrint(
        '[ContactTile] _startCooldown - Cooldown started for contact: ${_contact.userId}. _inCooldown: $_inCooldown');
  }

  // This function now correctly updates state to show sent messages
  void _sendDefaultMessage() async {
    debugPrint(
        '[ContactTile] _sendDefaultMessage called for contact: ${_contact.userId}');
    final String defaultMessage = AppConfig.getDefaultPlopMessage(context);
    debugPrint(
        '[ContactTile] _sendDefaultMessage - Default message: "$defaultMessage" for contact: ${_contact.userId}');
    _sendCustomMessage(defaultMessage);
  }

  void _sendCustomMessage(String message) async {
    debugPrint(
        '[ContactTile] _sendCustomMessage called for contact: ${_contact.userId} with message: "$message"');
    if (_inCooldown) {
      debugPrint(
          '[ContactTile] _sendCustomMessage - In cooldown for contact: ${_contact.userId}, returning.');
      return;
    }

    debugPrint(
        '[ContactTile] _sendCustomMessage - Updating contact state before sending for: ${_contact.userId}');
    setState(() {
      _contact.lastMessageSent = message;
      _contact.lastMessageSentStatus = MessageStatus.sending;
      _contact.lastMessageSentTimestamp = DateTime.now();
      _contact.lastMessageSentError = null; // Réinitialise l'erreur précédente
    });

    await _contact.save();
    debugPrint(
        '[ContactTile] _sendCustomMessage - Contact saved. Attempting to send message via WebSocket for: ${_contact.userId}');
    try {
      _webSocketService.sendMessage(
          type: 'plop', to: _contact.userId, payload: message, isDefault: true);
      debugPrint(
          '[ContactTile] _sendCustomMessage - Message sent via WebSocket. Starting cooldown for: ${_contact.userId}');

      _startCooldown();

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        debugPrint(
            '[ContactTile] _sendCustomMessage - Updating contact status to SENT for: ${_contact.userId}');
        setState(() {
          _contact.lastMessageSentStatus = MessageStatus.sent;
        });
        await _contact.save();
        debugPrint(
            '[ContactTile] _sendCustomMessage - Contact saved with SENT status for: ${_contact.userId}');
      } else {
        debugPrint(
            '[ContactTile] _sendCustomMessage - Widget not mounted after delay for contact: ${_contact.userId}, cannot update to SENT.');
      }
    } catch (e, s) {
      debugPrint(
          '[ContactTile] _sendCustomMessage - ERROR sending message for contact: ${_contact.userId}. Error: $e\nStackTrace: $s');
      // Si l'envoi échoue, on met à jour l'UI avec le statut "échec"
      if (mounted) {
        debugPrint(
            '[ContactTile] _sendCustomMessage - Updating contact status to FAILED for: ${_contact.userId}');
        setState(() {
          _contact.lastMessageSentStatus = MessageStatus.failed;
          _contact.lastMessageSentError =
              e.toString(); // On stocke l'erreur pour le tooltip
        });
        await _contact.save();
        debugPrint(
            '[ContactTile] _sendCustomMessage - Contact saved with FAILED status for: ${_contact.userId}');
      } else {
        debugPrint(
            '[ContactTile] _sendCustomMessage - Widget not mounted after error for contact: ${_contact.userId}, cannot update to FAILED.');
      }
    }
  }

  void _handleLongPress() {
    debugPrint(
        '[ContactTile] _handleLongPress called for contact: ${_contact.userId}. _inCooldown: $_inCooldown');
    if (_inCooldown) {
      debugPrint(
          '[ContactTile] _handleLongPress - In cooldown for contact: ${_contact.userId}, returning.');
      return;
    }
    final List<MessageModel> messages = _databaseService.getAllMessages();
    debugPrint(
        '[ContactTile] _handleLongPress - Fetched ${messages.length} custom messages for contact: ${_contact.userId}');
    if (messages.isNotEmpty) {
      _showCustomMessageMenu(messages);
    } else {
      debugPrint(
          '[ContactTile] _handleLongPress - No custom messages to show for contact: ${_contact.userId}');
    }
  }

  void _showCustomMessageMenu(List<MessageModel> messages) {
    debugPrint(
        '[ContactTile] _showCustomMessageMenu called for contact: ${_contact.userId} with ${messages.length} messages.');
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
                debugPrint(
                    '[ContactTile] _showCustomMessageMenu - Custom message selected: "${message.text}" for contact: ${_contact.userId}');
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
    debugPrint(
        '[ContactTile] _toggleMute called for contact: ${_contact.userId}. Current _isMuted: $_isMuted');
    setState(() {
      _isMuted = !_isMuted;
    });
    _contact.isMuted = _isMuted;
    await _contact.save();
    debugPrint(
        '[ContactTile] _toggleMute - Contact ${_contact.userId} mute status saved as: $_isMuted');
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';
    // Use the current locale for date formatting
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.Hm(locale).format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '[ContactTile] build called for contact: ${_contact.userId} - Alias: ${_contact.alias}, Original: ${_contact.originalPseudo}');
    debugPrint(
        '[ContactTile] build - _inCooldown: $_inCooldown, _isMuted: $_isMuted, LastSent: ${_contact.lastMessageSent}, LastReceived: ${_contact.lastMessage}');
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
                                    builder: (context, child) =>
                                        Positioned.fill(
                                          child: CircularProgressIndicator(
                                            value:
                                            _cooldownProgressController.value,
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
                                if (_contact.lastMessage != null)
                                  _buildMessageBubble(context),
                                const Spacer(),
                                if (_contact.lastMessageSent != null)
                                  _buildMessageSentBubble(context),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up,
                          size: 20,
                          color: _isMuted ? Colors.red : Colors.grey.shade900),
                      onPressed: _toggleMute,
                      tooltip: _isMuted ? l10n.unmuteTooltip : l10n.muteTooltip,
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
    // Limited logging here as it's primarily a display widget
    // debugPrint('[ContactTile] _buildMessageBubble for contact: ${_contact.userId}, message: ${_contact.lastMessage}');
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
    // Limited logging here as it's primarily a display widget
    // debugPrint('[ContactTile] _buildMessageSentBubble for contact: ${_contact.userId}, message: ${_contact.lastMessageSent}, status: ${_contact.lastMessageSentStatus}');
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
    // Limited logging here as it's primarily a display widget
    // debugPrint('[ContactTile] _buildStatusIndicator for contact: ${_contact.userId}, status: $status');
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
      case MessageStatus.unknown:
        icon = Icons.pending;
        color = Colors.grey.shade600;
        text = l10n.statusPending;
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
    if (status == MessageStatus.failed &&
        _contact.lastMessageSentError != null) {
      return Tooltip(
        message: _contact.lastMessageSentError!,
        child: statusWidget,
      );
    } else {
      return Tooltip(
        message: text,
        child: statusWidget,
      );
    }
  }
}