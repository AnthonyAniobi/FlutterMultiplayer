import 'package:flutter/material.dart';

class WebRtcLobby extends StatefulWidget {
  const WebRtcLobby({super.key});

  @override
  State<WebRtcLobby> createState() => _WebRtcLobbyState();

  Route<dynamic> route(RouteSettings routes) {
    return MaterialPageRoute(builder: (context) => WebRtcLobby());
  }
}

class _WebRtcLobbyState extends State<WebRtcLobby> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
