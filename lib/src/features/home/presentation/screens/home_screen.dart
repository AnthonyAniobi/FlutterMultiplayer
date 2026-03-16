import 'package:flutter/material.dart';
import 'package:flutter_multiplayer/src/features/home/presentation/widgets/home_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  static Route<dynamic> route(RouteSettings settings) {
    return MaterialPageRoute(builder: (context) => HomeScreen());
  }
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home page")),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeButton(text: "TCP Connection", onPressed: _tcpConnection),
            SizedBox(height: 20),
            HomeButton(text: "Supabase Connection", onPressed: unimplemented),
            SizedBox(height: 20),
            HomeButton(text: "Firebase Connection", onPressed: unimplemented),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _tcpConnection() {}

  void unimplemented() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Feature not implemented"),
          content: Text(
            "Please check back later this feature has not been worked on",
          ),
        );
      },
    );
  }
}
