import 'package:flutter/material.dart';
import 'package:flutter_multiplayer/src/core/constants/tcp_constants.dart';
import 'package:flutter_multiplayer/src/core/enums/network_role.dart';
import 'package:flutter_multiplayer/src/features/tcp_lan/data/models/game_client.dart';
import 'package:flutter_multiplayer/src/features/tcp_lan/data/models/game_host.dart';
import 'package:flutter_multiplayer/src/features/tcp_lan/data/models/log_entry.dart';
import 'package:flutter_multiplayer/src/features/tcp_lan/data/models/net_message.dart';

class TcpGameScreen extends StatefulWidget {
  final NetworkRole role;
  final String hostIp; // local IP if host, remote IP if client

  const TcpGameScreen({super.key, required this.role, required this.hostIp});

  @override
  State<TcpGameScreen> createState() => _TcpGameScreenState();
}

class _TcpGameScreenState extends State<TcpGameScreen> {
  GameHost? _host;
  GameClient? _client;

  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  final List<LogEntry> _log = [];

  bool _connected = false;
  bool _waitingForPlayer = false;

  @override
  void initState() {
    super.initState();
    if (widget.role == NetworkRole.host) {
      _startHost();
    } else {
      _startClient();
    }
  }

  // ── Host setup ───────────────────────────────────────

  Future<void> _startHost() async {
    setState(() => _waitingForPlayer = true);
    _addSystem('Hosting on ${widget.hostIp}:$kPort … waiting for player 2');
    _host = GameHost(
      onClientConnected: _onPeerConnected,
      onMessage: _onMessageReceived,
      onClientDisconnected: _onPeerDisconnected,
    );
    try {
      await _host!.start();
    } catch (e) {
      _addSystem('ERROR: Could not bind port $kPort — $e');
    }
  }

  // ── Client setup ─────────────────────────────────────

  Future<void> _startClient() async {
    _addSystem('Connecting to ${widget.hostIp}:$kPort …');
    _client = GameClient(
      onMessage: _onMessageReceived,
      onDisconnected: _onPeerDisconnected,
    );
    try {
      await _client!.connect(widget.hostIp);
      _onPeerConnected();
    } catch (e) {
      _addSystem(
        'ERROR: Connection failed — $e\n'
        'Check that the host IP is correct and both devices are on the same Wi-Fi.',
      );
    }
  }

  // ── Shared callbacks ─────────────────────────────────

  void _onPeerConnected() {
    setState(() {
      _connected = true;
      _waitingForPlayer = false;
    });
    _addSystem(
      widget.role == NetworkRole.host
          ? 'Player 2 joined! You can now send messages.'
          : 'Connected to host! You can now send messages.',
    );
  }

  void _onMessageReceived(NetMessage msg) {
    switch (msg.type) {
      case kMsgChat:
        _addLog('Them: ${msg.payload['text'] ?? ''}', isMine: false);
      case kMsgPing:
        _addSystem('Ping received from peer');
      // Add your own game message types here:
      // case 'move':
      //   _handleMove(msg.payload);
      default:
        _addSystem('[${msg.type}] ${msg.payload}');
    }
  }

  void _onPeerDisconnected() {
    if (!mounted) return;
    setState(() => _connected = false);
    _addSystem('⚠ The other player has left the game.');
    // Show a dialog so it's unmissable.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Player disconnected'),
        content: const Text(
          'The other player has left or lost connection. '
          'Return to the lobby to start a new session.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).pop(); // back to lobby
            },
            child: const Text('Back to lobby'),
          ),
        ],
      ),
    );
  }

  // ── Sending ──────────────────────────────────────────

  void _sendChat() {
    final text = _msgController.text.trim();
    if (text.isEmpty || !_connected) return;

    final msg = NetMessage(type: kMsgChat, payload: {'text': text});
    _host?.send(msg);
    _client?.send(msg);

    _addLog('Me: $text', isMine: true);
    _msgController.clear();
  }

  void _sendPing() {
    if (!_connected) return;
    final msg = NetMessage(
      type: kMsgPing,
      payload: {'ts': DateTime.now().millisecondsSinceEpoch},
    );
    _host?.send(msg);
    _client?.send(msg);
    _addSystem('Ping sent');
  }

  // ── Log helpers ──────────────────────────────────────

  void _addSystem(String text) {
    if (!mounted) return;
    setState(() => _log.add(LogEntry(text, isSystem: true)));
    _scrollToBottom();
  }

  void _addLog(String text, {required bool isMine}) {
    if (!mounted) return;
    setState(() => _log.add(LogEntry(text, isMine: isMine)));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Cleanup ──────────────────────────────────────────

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    // Graceful shutdown — tell the peer we're leaving.
    _host?.stop();
    _client?.disconnect();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleLabel = widget.role == NetworkRole.host ? 'Host' : 'Client';

    return PopScope(
      // Intercept back button to close connections gracefully.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _host?.stop();
        await _client?.disconnect();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('$roleLabel — LAN Game'),
          actions: [
            // Connection status indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    _connected ? Icons.circle : Icons.circle_outlined,
                    size: 12,
                    color: _connected ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _connected
                        ? 'Connected'
                        : _waitingForPlayer
                        ? 'Waiting…'
                        : 'Disconnected',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // ── Info bar ───────────────────────────────
            if (!_connected)
              MaterialBanner(
                backgroundColor: _waitingForPlayer
                    ? theme.colorScheme.tertiaryContainer
                    : theme.colorScheme.errorContainer,
                content: Text(
                  _waitingForPlayer
                      ? 'Waiting for player 2 to connect to ${widget.hostIp}:$kPort'
                      : 'Not connected',
                  style: TextStyle(
                    color: _waitingForPlayer
                        ? theme.colorScheme.onTertiaryContainer
                        : theme.colorScheme.onErrorContainer,
                  ),
                ),
                actions: const [SizedBox.shrink()],
              ),

            // ── Message log ────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _log.length,
                itemBuilder: (_, i) {
                  final entry = _log[i];
                  if (entry.isSystem) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Center(
                        child: Text(
                          entry.text,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return Align(
                    alignment: entry.isMine
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        color: entry.isMine
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(entry.isMine ? 16 : 4),
                          bottomRight: Radius.circular(entry.isMine ? 4 : 16),
                        ),
                      ),
                      child: Text(
                        entry.text,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: entry.isMine
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Input bar ──────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    // Ping button — useful for testing the connection
                    IconButton.outlined(
                      onPressed: _connected ? _sendPing : null,
                      icon: const Icon(Icons.radar, size: 20),
                      tooltip: 'Send ping',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        enabled: _connected,
                        decoration: const InputDecoration(
                          hintText: 'Type a message…',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _sendChat(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _connected ? _sendChat : null,
                      child: const Text('Send'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
