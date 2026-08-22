class Rotor {
  final String wiring;
  final String notch;
  int position = 0;
  int ringSetting = 0;

  Rotor(this.wiring, this.notch);

  // A->0, B->1, etc.
  int _charToInt(String char) => char.codeUnitAt(0) - 'A'.codeUnitAt(0);
  String _intToChar(int code) => String.fromCharCode(code + 'A'.codeUnitAt(0));

  int get notchPosition => _charToInt(notch);

  void setPosition(int newPosition) {
    position = newPosition % 26;
  }

  void setRingSetting(int newRingSetting) {
    ringSetting = newRingSetting % 26;
  }

  void advance() {
    position = (position + 1) % 26;
  }

  bool atNotch() {
    return position == notchPosition;
  }

  String forward(String char) {
    final int entryIndex = ( _charToInt(char) + position - ringSetting + 26) % 26;
    final String exitChar = wiring[entryIndex];
    final int exitIndex = _charToInt(exitChar);
    return _intToChar((exitIndex - position + ringSetting + 26) % 26);
  }

  String backward(String char) {
    final int entryIndex = (_charToInt(char) + position - ringSetting + 26) % 26;
    final String entryChar = _intToChar(entryIndex);
    final int exitIndex = wiring.indexOf(entryChar);
    return _intToChar((exitIndex - position + ringSetting + 26) % 26);
  }
}

// Dades històriques dels rotors de l'Enigma I
final Map<String, Map<String, String>> rotorData = {
  'I': {
    'wiring': 'EKMFLGDQVZNTOWYHXUSPAIBRCJ',
    'notch': 'Q'
  },
  'II': {
    'wiring': 'AJDKSIRUXBLHWTMCQGZNPYFVOE',
    'notch': 'E'
  },
  'III': {
    'wiring': 'BDFHJLCPRTXVZNYEIWGAKMUSQO',
    'notch': 'V'
  },
  'IV': {
    'wiring': 'ESOVPZJAYQUIRHXLNFTGKDCMWB',
    'notch': 'J'
  },
  'V': {
    'wiring': 'VZBRGITYUPSDNHLXAWMJQOFECK',
    'notch': 'Z'
  }
};
