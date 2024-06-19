import 'package:flutter/material.dart';

class NumberContainer extends StatelessWidget {
  final String number;
  final VoidCallback onTap;
  final Color? backgroundColor; // Background color of the container
  final bool isDoubleWidth;

  const NumberContainer(this.number, this.onTap,
      {super.key, this.backgroundColor, this.isDoubleWidth = false});

  @override
  Widget build(BuildContext context) {
    return isDoubleWidth
        ? Expanded(
            flex: 2, // Occupies two times the width of a regular button
            child: _buildContainer(),
          )
        : Expanded(
            child: _buildContainer(),
          );
  }

  Widget _buildContainer() {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? const Color(0xffF1F1F1),
          // Default background color
          borderRadius: BorderRadius.circular(10), // Rounded border
        ),
        padding: const EdgeInsets.fromLTRB(25.0, 8.0, 25.0, 8.0), // Padding
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
