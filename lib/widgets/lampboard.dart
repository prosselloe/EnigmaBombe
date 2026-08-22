import 'package:flutter/material.dart';

class Lampboard extends StatelessWidget {
  final String? illuminatedLetter;

  const Lampboard({super.key, this.illuminatedLetter});

  @override
  Widget build(BuildContext context) {
    final letters = 'QWERTZUIOASDFGHJKPYXCVBNML'.split('');

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 9,
        childAspectRatio: 1.2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: letters.length,
      itemBuilder: (context, index) {
        final letter = letters[index];
        final isLit = letter == illuminatedLetter;

        return Container(
          decoration: BoxDecoration(
            color: isLit ? Colors.yellow.shade600 : Colors.grey.shade800,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black54, width: 2),
            boxShadow: [
              if (isLit)
                BoxShadow(
                  color: Colors.yellow.withAlpha(128), // Alternativa a withOpacity
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 0),
                ),
            ],
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                color: isLit ? Colors.black : Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        );
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }
}
