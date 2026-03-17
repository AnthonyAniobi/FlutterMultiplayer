import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class GameConnection {
  late IO.Socket socket;
  late RTCPeerConnection peerConnection;
  RTCDataChannel? dataChannel;

  final _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      // Add TURN server here for production
    ],
  };

  Future<void> init() async {
    socket = IO.io('https://your-server.com', <String, dynamic>{
      'transports': ['websocket'],
    });

    peerConnection = await createPeerConnection(_iceServers);

    // Forward ICE candidates to peer via server
    peerConnection.onIceCandidate = (candidate) {
      socket.emit('ice_candidate', {
        'code': currentRoomCode,
        'candidate': candidate.toMap(),
      });
    };

    socket.on('ice_candidate', (data) async {
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      await peerConnection.addCandidate(candidate);
    });
  }

  // HOST: generate a code and wait
  Future<String> createRoom() async {
    final code = _generateCode(); // e.g. "XKCD9"

    // Create data channel (host side)
    dataChannel = await peerConnection.createDataChannel(
      'game',
      RTCDataChannelInit(),
    );
    dataChannel!.onMessage = (msg) => handleGameData(msg.text);

    // Create WebRTC offer
    final offer = await peerConnection.createOffer();
    await peerConnection.setLocalDescription(offer);

    socket.emit('create_room', {'code': code, 'offer': offer.toMap()});

    // When guest joins, complete the handshake
    socket.on('guest_joined', (data) async {
      final answer = RTCSessionDescription(
        data['answer']['sdp'],
        data['answer']['type'],
      );
      await peerConnection.setRemoteDescription(answer);
    });

    return code;
  }

  // GUEST: enter code and connect
  Future<void> joinRoom(String code) async {
    // Receive data channel (guest side)
    peerConnection.onDataChannel = (channel) {
      dataChannel = channel;
      dataChannel!.onMessage = (msg) => handleGameData(msg.text);
    };

    // Get host's offer from server
    socket.emit('request_offer', {'code': code});
    socket.on('room_offer', (data) async {
      final offer = RTCSessionDescription(
        data['offer']['sdp'],
        data['offer']['type'],
      );
      await peerConnection.setRemoteDescription(offer);

      final answer = await peerConnection.createAnswer();
      await peerConnection.setLocalDescription(answer);

      socket.emit('join_room', {'code': code, 'answer': answer.toMap()});
    });
  }

  void sendGameData(String json) {
    dataChannel?.send(RTCDataChannelMessage(json));
  }

  void handleGameData(String json) {
    // Parse and apply game state update
    print('Received: $json');
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(
      5,
      (_) => chars[DateTime.now().microsecondsSinceEpoch % chars.length],
    ).join();
  }
}
