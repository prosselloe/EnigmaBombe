import 'rotor.dart';
import 'reflector.dart';
import 'plugboard.dart';

class EnigmaMachine {
  Plugboard plugboard = Plugboard();
  List<Rotor> rotors = [];
  Reflector? reflector;

  List<String> _currentRotorNames = [];
  List<int> _currentRingSettings = [];
  String? _currentReflectorName;

  List<String> get rotorNames => _currentRotorNames;
  List<int> get ringSettings => _currentRingSettings;
  String? get reflectorName => _currentReflectorName;
  Map<String, String> get plugboardConnections => plugboard.connections;

  void setConfiguration({
    required List<String> rotorNames,
    required List<int> rotorPositions,
    required List<int> ringSettings,
    required String reflectorName,
    Map<String, String> plugboardConnections = const {},
  }) {
    final bool rotorConfigChanged = rotorNames.toString() != _currentRotorNames.toString() || ringSettings.toString() != _currentRingSettings.toString();
    if (rotorConfigChanged) {
      rotors = rotorNames.map((name) => Rotor(rotorData[name]!['wiring']!, rotorData[name]!['notch']!)).toList();
      for (int i = 0; i < rotors.length; i++) {
        rotors[i].setRingSetting(ringSettings[i]);
      }
      _currentRotorNames = List.from(rotorNames);
      _currentRingSettings = List.from(ringSettings);
    }
    
    setRotorPositions(rotorPositions);

    if (reflectorName != _currentReflectorName) {
      reflector = Reflector(reflectorData[reflectorName]!);
      _currentReflectorName = reflectorName;
    }

    plugboard.clear();
    plugboardConnections.forEach((key, value) {
      plugboard.addConnection(key, value);
    });
  }

  // Mètodes per a gestionar les posicions dels rotors
  void setRotorPositions(List<int> positions) {
    for (int i = 0; i < rotors.length; i++) {
      rotors[i].setPosition(positions[i]);
    }
  }

  List<int> getRotorPositions() {
    return rotors.map((r) => r.position).toList();
  }

  List<bool> getNotches() {
      return rotors.map((r) => r.atNotch()).toList();
  }

  List<int> getNotchPositions() {
      return rotors.map((r) => r.notchPosition).toList();
  }

  String encrypt(String message, {bool resetPositions = false}) {
    if (resetPositions) {
      setRotorPositions(List.filled(rotors.length, 0));
    }
    return message.toUpperCase().split('').map((char) {
      if (char.codeUnitAt(0) < 'A'.codeUnitAt(0) || char.codeUnitAt(0) > 'Z'.codeUnitAt(0)) {
        return char;
      }
      advanceRotors();
      return processChar(char);
    }).join();
  }

  String processChar(String char) {
    var processedChar = plugboard.swap(char);
    for (int i = rotors.length - 1; i >= 0; i--) {
      processedChar = rotors[i].forward(processedChar);
    }
    if (reflector != null) {
      processedChar = reflector!.reflect(processedChar);
    }
    for (int i = 0; i < rotors.length; i++) {
      processedChar = rotors[i].backward(processedChar);
    }
    processedChar = plugboard.swap(processedChar);
    return processedChar;
  }

  void advanceRotors() {
    if (rotors.length < 3) return;

    final rotorRight = rotors[2];
    final rotorMiddle = rotors[1];
    final rotorLeft = rotors[0];

    if (rotorMiddle.atNotch()) {
        rotorLeft.advance();
        rotorMiddle.advance();
    } else if (rotorRight.atNotch()) {
        rotorMiddle.advance();
    }
    rotorRight.advance();
  }
}
