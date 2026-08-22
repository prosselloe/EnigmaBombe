class Reflector {
  final String wiring;

  Reflector(this.wiring);

  String reflect(String char) {
    final int index = char.codeUnitAt(0) - 'A'.codeUnitAt(0);
    return wiring[index];
  }
}

// Dades històriques dels reflectors
final Map<String, String> reflectorData = {
  'B': 'YRUHQSLDPXNGOKMIEBFZCWVJAT',
  'C': 'FVPJIAOYEDRZXWGCTKUQSBNMHL'
};
