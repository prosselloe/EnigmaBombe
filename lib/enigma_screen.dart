import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bombe_screen.dart';
import 'enigma_logic/enigma_machine.dart';
import 'widgets/keyboard.dart';
import 'widgets/lampboard.dart';

// Estat global per a la màquina Enigma
class EnigmaState with ChangeNotifier {
  final EnigmaMachine _machine = EnigmaMachine();
  String _inputText = '';
  String _outputText = '';
  String? _illuminatedLetter;
  Timer? _lampTimer;

  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isFirstLoad = true;

  // Configuració de la màquina
  final List<String> _rotorNames = ['I', 'II', 'III'];
  List<int> _rotorPositions = [0, 0, 0];
  final List<int> _ringSettings = [0, 0, 0];
  String _reflectorName = 'B';
  final Map<String, String> _plugboardConnections = {};

  // Getters
  String get inputText => _inputText;
  String get outputText => _outputText;
  String? get illuminatedLetter => _illuminatedLetter;
  TextEditingController get inputController => _inputController;
  FocusNode get inputFocusNode => _inputFocusNode;
  List<String> get rotorNames => _rotorNames;
  List<int> get rotorPositions => _rotorPositions;
  String get reflectorName => _reflectorName;
  Map<String, String> get plugboardConnections => _plugboardConnections;

  EnigmaState() {
    _applyConfiguration();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    _lampTimer?.cancel();
    super.dispose();
  }
  
  void setInputText(String text) {
    _inputText = text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    _inputController.text = _inputText;
    _inputController.selection = TextSelection.fromPosition(TextPosition(offset: _inputText.length));
    _applyConfiguration(); // Re-xifra el nou text
  }

  void setInitialFocus() {
    if (_isFirstLoad && !_inputFocusNode.hasFocus) {
      _inputFocusNode.requestFocus();
      _isFirstLoad = false;
    }
  }

  void _applyConfiguration() {
    _machine.setConfiguration(
      rotorNames: _rotorNames,
      rotorPositions: _rotorPositions,
      ringSettings: _ringSettings,
      reflectorName: _reflectorName,
      plugboardConnections: _plugboardConnections,
    );
    _outputText = _machine.encrypt(_inputText);
    notifyListeners();
  }

  void typeKey(String key) {
    if (key.length != 1 || !RegExp(r'[A-Z]').hasMatch(key)) return;

    _machine.advanceRotors();
    final encryptedChar = _machine.processChar(key);
    _rotorPositions = _machine.getRotorPositions();

    _inputText += key;
    _outputText += encryptedChar;

    _inputController.text = _inputText;
    _inputController.selection = TextSelection.fromPosition(TextPosition(offset: _inputText.length));

    _illuminatedLetter = encryptedChar;
    _lampTimer?.cancel();
    _lampTimer = Timer(const Duration(milliseconds: 500), () {
      _illuminatedLetter = null;
      notifyListeners();
    });

    notifyListeners();
  }

  void pasteText(String text) {
    final sanitized = text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    for (var char in sanitized.split('')) {
      typeKey(char);
    }
  }

  void reset() {
    _inputText = '';
    _outputText = '';
    _illuminatedLetter = null;
    _rotorPositions = [0, 0, 0];
    _plugboardConnections.clear();
    _inputController.clear();
    _applyConfiguration();
    _inputFocusNode.requestFocus();
  }

  void setRotor(int index, String name) {
    _rotorNames[index] = name;
    _applyConfiguration();
  }

  void setRotorPosition(int index, int position) {
    _rotorPositions[index] = position;
    _applyConfiguration();
  }

  void setReflector(String name) {
    _reflectorName = name;
    _applyConfiguration();
  }

  void addPlugboardConnection(String char1, String char2) {
    _plugboardConnections[char1] = char2;
    _plugboardConnections[char2] = char1;
    _applyConfiguration();
  }

  void removePlugboardConnection(String char) {
    final connected = _plugboardConnections[char];
    if (connected != null) {
      _plugboardConnections.remove(char);
      _plugboardConnections.remove(connected);
      _applyConfiguration();
    }
  }
}

class EnigmaScreen extends StatefulWidget {
  const EnigmaScreen({super.key});

  @override
  State<EnigmaScreen> createState() => _EnigmaScreenState();
}

class _EnigmaScreenState extends State<EnigmaScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _rotorAnimController;
  final List<Animation<double>> _rotorAnimations = [];
  List<int> _previousRotorPositions = [0, 0, 0];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _rotorAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    for (int i = 0; i < 3; i++) {
      _rotorAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _rotorAnimController, curve: Curves.easeInOutCubic),
        ),
      );
    }

    final state = Provider.of<EnigmaState>(context, listen: false);
    state.addListener(_onEnigmaStateChanged);
    _previousRotorPositions = List.from(state.rotorPositions);
  }

  void _onEnigmaStateChanged() {
    final state = Provider.of<EnigmaState>(context, listen: false);
    final newPositions = state.rotorPositions;

    if (mounted) {
      bool needsAnimation = false;
      for (int i = 0; i < 3; i++) {
        if (_previousRotorPositions[i] != newPositions[i]) {
          needsAnimation = true;
          break;
        }
      }

      if (needsAnimation) {
        _rotorAnimController.forward(from: 0.0);
      }
      
      _previousRotorPositions = List.from(newPositions);
    }
  }

  @override
  void dispose() {
    _rotorAnimController.dispose();
    Provider.of<EnigmaState>(context, listen: false).removeListener(_onEnigmaStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<EnigmaState>(
      builder: (context, state, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) => state.setInitialFocus());

        return Scaffold(
          backgroundColor: Colors.grey[850],
          floatingActionButton: FloatingActionButton(
            onPressed: state.reset,
            tooltip: 'Reiniciar i Esborrar Text',
            backgroundColor: Colors.red[700],
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDisplay(context, state),
                  const SizedBox(height: 20),
                  Lampboard(illuminatedLetter: state.illuminatedLetter),
                  const SizedBox(height: 20),
                  Keyboard(onKeyPressed: state.typeKey),
                  const SizedBox(height: 30),
                  _buildAnimatedConfigurationPanel(context, state),
                  const SizedBox(height: 24),
                  _buildPlugboard(context, state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDisplay(BuildContext context, EnigmaState state) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             TextField(
              controller: state.inputController,
              focusNode: state.inputFocusNode,
              autofocus: true,
              readOnly: false, // Permet l'entrada del teclat
              showCursor: true,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'monospace'),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                labelText: 'ENTRADA',
                 labelStyle: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              onChanged: (text) => state.setInputText(text),
            ),
            const Divider(color: Colors.grey),
            const Text('SORTIDA:', style: TextStyle(color: Colors.yellow, fontSize: 12)),
            SelectableText(
              state.outputText,
              style: const TextStyle(color: Colors.yellow, fontSize: 20, fontFamily: 'monospace'),
            ),
             if (state.outputText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                    label: const Text('Provar a la Bombe'),
                    onPressed: () {
                      final bombeState = Provider.of<BombeState>(context, listen: false);
                      final enigmaState = Provider.of<EnigmaState>(context, listen: false);
                      
                      bombeState.setCiphertext(enigmaState.outputText);
                      bombeState.setCrib(enigmaState.inputText);

                      DefaultTabController.of(context).animateTo(1);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedConfigurationPanel(BuildContext context, EnigmaState state) {
     return Card(
      color: Colors.grey[900],
      elevation: 4,
      child: ExpansionTile(
        title: const Text('Configuració de Rotors i Reflector', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        initiallyExpanded: true, 
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...List.generate(3, (i) => _buildAnimatedRotor(state, i)),
                _buildReflectorControl(state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedRotor(EnigmaState state, int i) {
    final alphabet = List.generate(26, (j) => String.fromCharCode('A'.codeUnitAt(0) + j));
    final rotorChoices = ['I', 'II', 'III', 'IV', 'V'];

    return Column(
      children: [
        DropdownButton<String>(
          value: state.rotorNames[i],
          items: rotorChoices.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (val) => state.setRotor(i, val!),
          dropdownColor: Colors.grey[800],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          isExpanded: false,
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _rotorAnimations[i],
          builder: (context, child) {
            final previousPos = _previousRotorPositions[i];
            final currentPos = state.rotorPositions[i];
            final angle = (_rotorAnimations[i].value * (currentPos - previousPos)) * (2 * 3.14159 / 26);

            return Transform.rotate(
              angle: angle,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 2),
                  color: Colors.black.withAlpha(50),
                ),
                child: Text(
                  alphabet[currentPos],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            );
          },
        ),
         const SizedBox(height: 10),
         DropdownButton<int>(
          value: state.rotorPositions[i],
          items: List.generate(26, (j) => DropdownMenuItem(value: j, child: Text(alphabet[j]))).toList(),
          onChanged: (val) => state.setRotorPosition(i, val!),
          dropdownColor: Colors.grey[800],
          style: const TextStyle(color: Colors.white),
          isExpanded: false,
        ),
      ],
    );
  }

  Widget _buildReflectorControl(EnigmaState state) {
    final reflectorChoices = ['B', 'C'];
    return Column(
      children: [
        const Text('Reflector', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
         const SizedBox(height: 10),
        DropdownButton<String>(
          value: state.reflectorName,
          items: reflectorChoices.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (val) => state.setReflector(val!),
          dropdownColor: Colors.grey[800],
          style: const TextStyle(color: Colors.white),
          isExpanded: false,
        ),
      ],
    );
  }


  Widget _buildPlugboard(BuildContext context, EnigmaState state) {
    final alphabet = List.generate(26, (i) => String.fromCharCode('A'.codeUnitAt(0) + i));
    final TextEditingController plugboardController = TextEditingController();

    return Card(
      color: Colors.grey[900],
      elevation: 4,
      child: ExpansionTile(
        title: const Text('Panell de Connexions (Plugboard)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: state.plugboardConnections.entries.map((entry) {
                    if (entry.key.compareTo(entry.value) < 0) {
                      return Chip(
                        label: Text('${entry.key} - ${entry.value}'),
                        onDeleted: () => state.removePlugboardConnection(entry.key),
                        backgroundColor: Colors.grey[700],
                        labelStyle: const TextStyle(color: Colors.white),
                      );
                    }
                    return const SizedBox.shrink();
                  }).toList(),
                ),
                const SizedBox(height: 16),
                if (state.plugboardConnections.length < 20) 
                  TextField(
                    controller: plugboardController,
                    maxLength: 2,
                    decoration: InputDecoration(
                      labelText: 'Afegir connexió (ex: AB)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      counterText: '',
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.yellow),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      if (value.length == 2) {
                        final char1 = value[0].toUpperCase();
                        final char2 = value[1].toUpperCase();
                        if (alphabet.contains(char1) && alphabet.contains(char2) && char1 != char2 && !state.plugboardConnections.containsKey(char1) && !state.plugboardConnections.containsKey(char2)) {
                          state.addPlugboardConnection(char1, char2);
                           Future.delayed(const Duration(milliseconds: 100), () {
                            plugboardController.clear();
                          });
                        } else {
                           plugboardController.clear();
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
