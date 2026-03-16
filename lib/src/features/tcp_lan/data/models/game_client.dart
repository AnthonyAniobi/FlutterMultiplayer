import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_multiplayer/src/core/constants/tcp_constants.dart';
import 'package:flutter_multiplayer/src/features/tcp_lan/data/models/net_message.dart';

class GameClient {
  Socket? _socket;

  final void Function(NetMessage msg) onMessage;
  final void Function() onDisconnected;

  GameClient({required this.onMessage, required this.onDisconnected});

  // ── Connect ──────────────────────────────────────────

  Future<void> connect(String hostIp) async {
    _socket = await Socket.connect(
      hostIp,
      kPort,
      timeout: const Duration(seconds: 6),
    );
    debugPrint('[Client] Connected to $hostIp:$kPort');

    final buffer = StringBuffer();

    _socket!
        .transform(utf8.decoder)
        .listen(
          (chunk) {
            buffer.write(chunk);
            final raw = buffer.toString();
            final lines = raw.split('\n');
            buffer.clear();
            buffer.write(lines.last);
            for (final line in lines.sublist(0, lines.length - 1)) {
              if (line.trim().isEmpty) continue;
              try {
                final msg = NetMessage.fromJson(line);
                if (msg.type == kMsgDisconnect) {
                  // Host sent an intentional goodbye.
                  onDisconnected();
                  return;
                }
                onMessage(msg);
              } catch (e) {
                debugPrint('[Client] Malformed message: $e');
              }
            }
          },
          onDone: onDisconnected,
          onError: (_) => onDisconnected(),
          cancelOnError: true,
        );
  }

  // ── Send to host ─────────────────────────────────────

  void send(NetMessage msg) {
    try {
      _socket?.write('${msg.toJson()}\n');
    } catch (e) {
      debugPrint('[Client] Send error: $e');
    }
  }

  // ── Graceful disconnect ──────────────────────────────

  Future<void> disconnect() async {
    send(NetMessage(type: kMsgDisconnect, payload: {'reason': 'client left'}));
    await Future.delayed(const Duration(milliseconds: 100));
    await _socket?.close();
    _socket = null;
  }
}
