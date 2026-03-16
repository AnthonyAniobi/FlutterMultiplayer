import 'package:flutter/material.dart';
import 'package:flutter_multiplayer/src/core/enums/network_role.dart';
import 'package:flutter_multiplayer/src/features/tcp_lan/data/models/game_host.dart';
import 'package:flutter_multiplayer/src/features/tcp_lan/presentation/screens/tcp_game_screen.dart';

class TcpLobbyScreen extends StatefulWidget {
  const TcpLobbyScreen({super.key});

  @override
  State<TcpLobbyScreen> createState() => _TcpLobbyScreenState();
}

class _TcpLobbyScreenState extends State<TcpLobbyScreen> {
  final _ipController = TextEditingController();
  String _localIp = 'discovering...';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _discoverIp();
  }

  Future<void> _discoverIp() async {
    final ip = await GameHost.getLocalIp();
    if (mounted) setState(() => _localIp = ip);
  }

  // ── Host flow ────────────────────────────────────────

  Future<void> _hostGame() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final host = GameHost(
        onMessage: (_) {}, // wired up inside GameScreen
        onClientDisconnected: () {},
        onClientConnected: () {},
      );
      await host.stop(); // pre-stop in case port is in use — harmless
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TcpGameScreen(role: NetworkRole.host, hostIp: _localIp),
        ),
      );
    } catch (e) {
      setState(() => _error = 'Could not start server: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Client flow ──────────────────────────────────────

  Future<void> _joinGame() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      setState(() => _error = 'Enter the host IP address first.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TcpGameScreen(role: NetworkRole.client, hostIp: ip),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('LAN Multiplayer Demo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Your IP card ───────────────────────────
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your device IP',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      _localIp,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share this with the other player so they can join.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Host button ────────────────────────────
            FilledButton.icon(
              onPressed: _loading ? null : _hostGame,
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Host a game'),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or join'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
            ),

            // ── Join form ──────────────────────────────
            TextField(
              controller: _ipController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Host IP address',
                hintText: '192.168.x.x',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wifi),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _joinGame,
              icon: const Icon(Icons.login),
              label: const Text('Join game'),
            ),

            if (_loading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
