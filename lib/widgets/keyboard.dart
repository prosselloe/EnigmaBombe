import 'package:flutter/material.dart';

class Keyboard extends StatelessWidget {
  final void Function(String) onKeyPressed;

  const Keyboard({super.key, required this.onKeyPressed});

  @override
  Widget build(BuildContext context) {
    // Disposició de les tecles en un sol array per al GridView
    final keys = 'QWERTZUIOASDFGHJKPYXCVBNML'.split('');

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 9, // Manté 9 tecles per fila com el lampboard
        childAspectRatio: 1.2, // Relació d'aspecte per a que siguin similars a cercles
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        return _buildKey(key);
      },
      shrinkWrap: true, // Per a que el GridView ocupi l'espai necessari
      physics: const NeverScrollableScrollPhysics(), // Deshabilita l'scroll dins el GridView
    );
  }

  Widget _buildKey(String char) {
    return ElevatedButton(
      onPressed: () => onKeyPressed(char),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        padding: EdgeInsets.zero, // El centrat el farà el GridView
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(char, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
