import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_multiplayer/src/core/constants/tcp_constants.dart';
import 'package:flutter_multiplayer/src/features/tcp_lan/data/models/net_message.dart';

class GameHost {
  ServerSocket? _server;
  Socket? _clientSocket;

  /// Called whenever a well-formed message arrives from the client.
  final void Function(NetMessage msg) onMessage;

  /// Called when the client disconnects (gracefully or via timeout).
  final void Function() onClientDisconnected;

  /// Called when a client successfully connects.
  final void Function() onClientConnected;

  GameHost({
    required this.onMessage,
    required this.onClientDisconnected,
    required this.onClientConnected,
  });

  // ── Start listening ──────────────────────────────────

  Future<void> start() async {
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, kPort);
    _server!.listen(
      _handleClient,
      onError: (e) => debugPrint('[Host] ServerSocket error: $e'),
    );
    debugPrint('[Host] Listening on port $kPort');
  }

  void _handleClient(Socket socket) {
    if (_clientSocket != null) {
      // Only one client supported in this demo — reject extras.
      socket.close();
      return;
    }
    _clientSocket = socket;
    debugPrint('[Host] Client connected: ${socket.remoteAddress.address}');
    onClientConnected();

    // TCP is a byte stream — split on newline so merged frames are handled.
    final buffer = StringBuffer();

    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .listen(
          (chunk) {
            buffer.write(chunk);
            final raw = buffer.toString();
            final lines = raw.split('\n');
            // The last element may be an incomplete frame — keep it in the buffer.
            buffer.clear();
            buffer.write(lines.last);
            for (final line in lines.sublist(0, lines.length - 1)) {
              if (line.trim().isEmpty) continue;
              try {
                final msg = NetMessage.fromJson(line);
                onMessage(msg);
              } catch (e) {
                debugPrint('[Host] Malformed message: $e');
              }
            }
          },
          onDone: _onClientGone,
          onError: (_) => _onClientGone(),
          cancelOnError: true,
        );
  }

  void _onClientGone() {
    debugPrint('[Host] Client disconnected');
    _clientSocket = null;
    onClientDisconnected();
  }

  // ── Send to client ───────────────────────────────────

  void send(NetMessage msg) {
    try {
      _clientSocket?.write(msg.toJson() + '\n');
    } catch (e) {
      debugPrint('[Host] Send error: $e');
    }
  }

  // ── Graceful shutdown ────────────────────────────────

  Future<void> stop() async {
    // Notify the client before closing.
    send(NetMessage(type: kMsgDisconnect, payload: {'reason': 'host left'}));
    await Future.delayed(const Duration(milliseconds: 100));
    await _clientSocket?.close();
    await _server?.close();
    _clientSocket = null;
    _server = null;
  }

  // ── Utility ──────────────────────────────────────────

  /// Returns the device's Wi-Fi LAN IP (the one to share with the other player).
  static Future<String> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final iface in interfaces) {
        // Prefer wlan (Android) or en (iOS/macOS).
        if (iface.name.startsWith('wlan') || iface.name.startsWith('en')) {
          return iface.addresses.first.address;
        }
      }
      // Fallback: first non-loopback IPv4.
      return interfaces.first.addresses.first.address;
    } catch (_) {
      return 'Unknown';
    }
  }
}
