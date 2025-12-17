import 'package:flutter/material.dart';

class AddLinkNativePage extends StatelessWidget {
  static String routeName = "/AddLinkNativePage";
  const AddLinkNativePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          color: Colors.white,
          child: Text("Popup nhận URL"),
        ),
      ),
    );
  }
}
