import 'package:flutter/material.dart';

class HomeButton extends StatelessWidget {
  final String text;
  final void Function()? onPressed;

  const HomeButton({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text, style: TextStyle(fontSize: 18)),
    );
  }
}
