import 'dart:isolate';
import 'dart:collection';
import '../enigma_logic/enigma_machine.dart';

/// Payload object for communication between the main isolate and the worker.
class WorkerPayload {
  final String crib;
  final String ciphertext;
  final String reflectorName;
  final List<List<String>> rotorOrders;

  WorkerPayload({
    required this.crib,
    required this.ciphertext,
    required this.reflectorName,
    required this.rotorOrders,
  });
}

/// Entry point for the isolate.
/// This function performs the actual cryptanalysis for a subset of configurations.
void bombeWorker(dynamic message) {
  final SendPort sendPort = message['sendPort'];
  final WorkerPayload payload = message['payload'];

  try {
    final enigma = EnigmaMachine();

    final menu = _buildMenu(payload.crib, payload.ciphertext.substring(0, payload.crib.length));
    if (menu == null) {
      sendPort.send({'type': 'error', 'message': 'Crib and ciphertext are not valid for analysis.'});
      return; // The finally block will still execute
    }

    int combinationsCheckedSinceLastReport = 0;
    bool resultFound = false;

    for (final rotorOrder in payload.rotorOrders) {
      if (resultFound) break; // Stop if a result has been found

      for (int p1 = 0; p1 < 26; p1++) {
        if (resultFound) break;

        for (int p2 = 0; p2 < 26; p2++) {
          if (resultFound) break;

          for (int p3 = 0; p3 < 26; p3++) {
            final startPositions = [p1, p2, p3];

            final isConsistent = _testConfigurationWithDiagonalBoard(
              enigma,
              rotorOrder,
              startPositions,
              payload.reflectorName,
              menu,
            );

            if (isConsistent) {
              enigma.setConfiguration(
                rotorNames: rotorOrder,
                rotorPositions: startPositions,
                ringSettings: [0, 0, 0], // For the Bombe, rings are tested later
                reflectorName: payload.reflectorName,
                plugboardConnections: {},
              );
              final encryptedCrib = enigma.encrypt(payload.crib);
              sendPort.send({
                'type': 'result',
                'rotorOrder': rotorOrder,
                'startPositions': startPositions,
                'encryptedCrib': encryptedCrib,
              });
              resultFound = true;
              break; // A stop was found, exit the inner loop
            }

            combinationsCheckedSinceLastReport++;
            if (combinationsCheckedSinceLastReport >= 5000) {
              sendPort.send({'type': 'progress', 'count': combinationsCheckedSinceLastReport});
              combinationsCheckedSinceLastReport = 0;
            }
          }
        }
      }
    }

    // Send any remaining progress
    if (combinationsCheckedSinceLastReport > 0) {
      sendPort.send({'type': 'progress', 'count': combinationsCheckedSinceLastReport});
    }
  } finally {
    // Ensure 'done' is always sent
    sendPort.send({'type': 'done'});
  }
}


// --- Helper functions moved from BombeSimulator ---

Map<int, Map<String, String>>? _buildMenu(String crib, String ciphertext) {
  final menu = <int, Map<String, String>>{};
  for (int i = 0; i < crib.length; i++) {
    if (crib[i] == ciphertext[i]) {
      return null;
    }
    menu[i] = {'crib': crib[i], 'cipher': ciphertext[i]};
  }
  return menu;
}

bool _testConfigurationWithDiagonalBoard(
  EnigmaMachine enigma,
  List<String> rotorOrder,
  List<int> startPositions,
  String reflectorName,
  Map<int, Map<String, String>> menu,
) {
  final plugboardHypothesis = <String, String>{};
  final queue = Queue<String>();

  final initialCribLetter = menu.values.first['crib']!;
  queue.add(initialCribLetter);
  plugboardHypothesis[initialCribLetter] = initialCribLetter;

  while (queue.isNotEmpty) {
    final currentLetter = queue.removeFirst();
    for (final position in menu.keys) {
      final cribLetter = menu[position]!['crib']!;
      final cipherLetter = menu[position]!['cipher']!;

      String? inputLetter;
      String? outputLetter;

      if (cribLetter == currentLetter) {
        inputLetter = cribLetter;
        outputLetter = cipherLetter;
      } else if (cipherLetter == currentLetter) {
        inputLetter = cipherLetter;
        outputLetter = cribLetter;
      }

      if (inputLetter != null && outputLetter != null) {
        enigma.setConfiguration(
          rotorNames: rotorOrder,
          rotorPositions: startPositions,
          ringSettings: [0, 0, 0],
          reflectorName: reflectorName,
          plugboardConnections: {},
        );

        for (int i = 0; i < position; i++) {
          enigma.advanceRotors();
        }
        enigma.advanceRotors();

        final enigmaOutput = enigma.processChar(plugboardHypothesis[inputLetter] ?? inputLetter);
        final deducedOutput = plugboardHypothesis[outputLetter];

        if (deducedOutput != null && deducedOutput != enigmaOutput) {
          return false; // Contradiction
        }
        if (plugboardHypothesis.containsKey(enigmaOutput) && plugboardHypothesis[enigmaOutput] != outputLetter) {
          return false; // Contradiction
        }

        if (deducedOutput == null) {
          plugboardHypothesis[enigmaOutput] = outputLetter;
          plugboardHypothesis[outputLetter] = enigmaOutput;
          queue.add(enigmaOutput);
          queue.add(outputLetter);
        }
      }
    }
  }
  return true;
}
