import 'package:flutter/material.dart';

class TcpLanHome extends StatefulWidget {
  const TcpLanHome({super.key});

  @override
  State<TcpLanHome> createState() => _TcpLanHomeState();
}

class _TcpLanHomeState extends State<TcpLanHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("TCP LAN")),
      body: Column(children: []),
    );
  }
}
