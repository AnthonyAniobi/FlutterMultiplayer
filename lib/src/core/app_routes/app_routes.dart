import 'package:flutter/material.dart';
import 'package:flutter_multiplayer/src/features/home/presentation/screens/home_screen.dart';
import 'package:flutter_multiplayer/src/features/tcp_lan/presentation/screens/tcp_lobby_screen.dart';

class AppRoutes {
  static String currentRoute = home;
  static const home = '/';
  static const tcpLobby = '/tcp-lobby';

  // generate routes
  static Route<dynamic>? onGenerateRoute(RouteSettings routeSettings) {
    currentRoute = routeSettings.name ?? currentRoute;
    return switch (routeSettings.name) {
      home => HomeScreen.route(routeSettings),
      tcpLobby => TcpLobbyScreen.route(routeSettings),
      _ => MaterialPageRoute(builder: (_) => Container()),
    };
  }
}
