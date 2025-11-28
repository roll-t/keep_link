import 'package:flutter/material.dart';

class ListLinkCollection extends StatelessWidget {
  const ListLinkCollection({super.key});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.only(top: 100, bottom: 30),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 20,
      itemBuilder: (context, index) {
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "Item ${index + 1}",
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        );
      },
    );
  }
}
