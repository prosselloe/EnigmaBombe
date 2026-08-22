
import 'dart:async';
import 'dart:collection';
import '../enigma_logic/enigma_machine.dart';

class BombeSimulator {
  final EnigmaMachine _enigma = EnigmaMachine();

  Stream<Map<String, dynamic>> findSettings(
    String crib,
    String ciphertext, {
    required String reflectorName,
    int? startCombination, // NOU
    int? endCombination,   // NOU
  }) async* {
    if (crib.length > ciphertext.length) {
      yield {'type': 'error', 'message': 'El crib no pot ser més llarg que el text xifrat.'};
      return;
    }
    
    final allAvailableRotors = ['I', 'II', 'III', 'IV', 'V'];
    final possibleRotorOrders = _getPermutations(allAvailableRotors, 3);
    int combinationsChecked = 0;
    
    final relevantCiphertext = ciphertext.substring(0, crib.length);
    final menu = _buildMenu(crib, relevantCiphertext);

    if (menu == null) {
      yield {'type': 'error', 'message': 'El crib i el text xifrat no són vàlids (una lletra no es pot xifrar com a ella mateixa).'};
      return;
    }

    final totalRotorOrders = possibleRotorOrders.length;
    final totalPositions = 26 * 26 * 26;
    final totalCombinations = totalRotorOrders * totalPositions;

    final searchStart = startCombination ?? 0;
    final searchEnd = endCombination ?? totalCombinations;

    for (int i = searchStart; i < searchEnd; i++) {
      final rotorOrderIndex = i ~/ totalPositions;
      final positionIndex = i % totalPositions;
      
      final rotorOrder = possibleRotorOrders[rotorOrderIndex];
      final p1 = positionIndex ~/ (26 * 26);
      final p2 = (positionIndex ~/ 26) % 26;
      final p3 = positionIndex % 26;
      final startPositions = [p1, p2, p3];

      final bool isConsistent = _testConfigurationWithDiagonalBoard(
        rotorOrder,
        startPositions,
        reflectorName,
        menu,
      );

      if (isConsistent) {
         _enigma.setConfiguration(
            rotorNames: rotorOrder,
            rotorPositions: startPositions,
            ringSettings: [0, 0, 0],
            reflectorName: reflectorName,
            plugboardConnections: {},
        );
        final encryptedCrib = _enigma.encrypt(crib);
        yield {
          'type': 'result',
          'rotorOrder': rotorOrder,
          'startPositions': startPositions,
          'encryptedCrib': encryptedCrib,
        };
        return; // Atura la cerca en trobar el primer resultat
      }

      combinationsChecked++;
      if (combinationsChecked % 5000 == 0) { 
        yield {
          'type': 'progress',
          'combinations_checked': combinationsChecked,
        };
        await Future.delayed(Duration.zero); 
      }
    }

     yield {
      'type': 'progress',
      'combinations_checked': combinationsChecked, 'status': 'completed'
    };
  }

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
           _enigma.setConfiguration(
              rotorNames: rotorOrder,
              rotorPositions: List.from(startPositions),
              ringSettings: [0, 0, 0],
              reflectorName: reflectorName,
              plugboardConnections: {},
            );
            
            for (int i = 0; i < position; i++) {
                _enigma.advanceRotors();
            }
            _enigma.advanceRotors();

            final enigmaOutput = _enigma.processChar(plugboardHypothesis[inputLetter] ?? inputLetter);

            final deducedOutput = plugboardHypothesis[outputLetter];
            if (deducedOutput != null && deducedOutput != enigmaOutput) {
                return false; 
            }
            if (plugboardHypothesis.containsKey(enigmaOutput) && plugboardHypothesis[enigmaOutput] != outputLetter) {
                return false;
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

  List<List<T>> _getPermutations<T>(List<T> list, int length) {
    final result = <List<T>>[];
    void permute(List<T> current, List<T> remaining) {
      if (current.length == length) {
        result.add(List<T>.from(current));
        return;
      }
      for (int i = 0; i < remaining.length; i++) {
        final next = remaining[i];
        current.add(next);
        final nextRemaining = List<T>.from(remaining)..removeAt(i);
        permute(current, nextRemaining);
        current.removeLast();
      }
    }
    permute([], list);
    return result;
  }
}
