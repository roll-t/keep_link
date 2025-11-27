import 'package:flutter/material.dart';
import 'package:keep_link/core/ui/text/text_widget.dart';

class SplashPage extends StatelessWidget {
  static const String routeName = "/SplashPage";
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(child: TextWidget(text: "center")),
    );
  }
}
