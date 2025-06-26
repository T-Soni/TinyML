import 'package:flutter/material.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';

class RaisedGradientButton extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final bool isActive;
  final bool isSelected;
  final double width;
  final double height;
  final VoidCallback onPressed;

  const RaisedGradientButton({
    super.key,
    required this.child,
    required this.gradient,
    // this.width = double.infinity,
    // this.height = 50.0,
    required this.isActive,
    required this.isSelected,
    this.width = 150.0,
    this.height = 80.0,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width,
        height: 80.0,
        // height: 50.0,
        decoration: BoxDecoration(
            border: GradientBoxBorder(
                gradient: (isSelected && !isActive)
                    ? LinearGradient(colors: [
                        const Color.fromARGB(255, 3, 3, 93),
                        const Color.fromARGB(255, 63, 91, 202)
                      ])
                    : gradient,
                width: 5),
            gradient: (isActive)
                ? gradient
                : LinearGradient(
                    colors: [Colors.transparent, Colors.transparent]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.white10,
                offset: Offset(0.0, 1.5),
                blurRadius: 1.5,
              ),
            ]),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
              onTap: onPressed,
              child: Center(
                child: child,
              )),
        ),
      ),
    );
  }
}
