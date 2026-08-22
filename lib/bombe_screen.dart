import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bombe_logic/bombe_simulator.dart';
import 'dart:developer' as developer;
import 'package:intl/intl.dart';
import '../enigma_screen.dart';
import 'package:audioplayers/audioplayers.dart';

// Estat de la Bombe
class BombeState with ChangeNotifier {
  final BombeSimulator _simulator = BombeSimulator();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _ciphertext = '';
  String _crib = '';
  bool _isRunning = false;
  bool _isPaused = false;
  List<Map<String, dynamic>> _results = [];
  StreamSubscription? _streamSubscription;
  bool _isCancelled = false;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsedTime = '00:00:00';
  int _combinationsChecked = 0;
  final int _totalCombinationsPerReflector = 1054560;
  String? _errorMessage;
  String _statusMessage = '';

  String _selectedReflector = 'B';
  List<Color> _rotorColors = List.generate(3, (_) => Colors.grey[700]!);
  Timer? _colorChangeTimer;

  // Getters
  String get ciphertext => _ciphertext;
  String get crib => _crib;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  bool get isCancelled => _isCancelled;
  List<Map<String, dynamic>> get results => _results;
  String get elapsedTime => _elapsedTime;
  int get combinationsChecked => _combinationsChecked;
  int get totalCombinations => _totalCombinationsPerReflector;
  String? get errorMessage => _errorMessage;
  String get statusMessage => _statusMessage;
  String get selectedReflector => _selectedReflector;
  List<Color> get rotorColors => _rotorColors;

  void setCiphertext(String text) {
    _ciphertext = text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    notifyListeners();
  }

  void setCrib(String text) {
    _crib = text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    notifyListeners();
  }

  void setReflector(String? reflector) {
    if (reflector != null) {
      _selectedReflector = reflector;
      notifyListeners();
    }
  }

   void _updateRotorColors() {
    final random = Random();
    _rotorColors = List.generate(3, (_) => Color.fromRGBO(
      50 + random.nextInt(206),
      50 + random.nextInt(206),
      50 + random.nextInt(206),
      1,
    ));
    notifyListeners();
  }

  Future<void> _runSimulationForReflector(String reflector) async {
    if (_isCancelled || _isPaused) return;

    _statusMessage = 'Provant amb Reflector $reflector...';
    if (!_isPaused) _combinationsChecked = 0;
    notifyListeners();

    final stream = _simulator.findSettings(_crib, _ciphertext, reflectorName: reflector);
    final completer = Completer<void>();

    _streamSubscription = stream.listen((data) {
      if (_isCancelled || _isPaused) {
        if (!completer.isCompleted) completer.complete();
        return;
      }
      if (data['type'] == 'result') {
        _results.add(data..['foundWithReflector'] = reflector);
        _playBellSound();
        _pauseForCandidate();
        if (!completer.isCompleted) completer.complete();
      } else if (data['type'] == 'progress') {
        _combinationsChecked = data['combinations_checked'];
      } else if (data['type'] == 'error') {
        _errorMessage = data['message'];
      }
      notifyListeners();
    }, onDone: () {
      if (!completer.isCompleted) completer.complete();
    }, onError: (e) {
      developer.log('Error en la simulació amb reflector $reflector: $e', name: 'bombe.simulation');
      if (!completer.isCompleted) completer.complete();
    });

    await completer.future;
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  Future<void> startOrResumeSimulation() async {
    if (_isRunning || _crib.isEmpty || _ciphertext.isEmpty) return;

    if (!_isPaused) {
      _results = [];
      _errorMessage = null;
      _combinationsChecked = 0;
      _stopwatch.reset();
    }

    _isRunning = true;
    _isPaused = false;
    _isCancelled = false;
    
    _stopwatch.start();
     _colorChangeTimer = Timer.periodic(const Duration(milliseconds: 400), (_) => _updateRotorColors());

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = _stopwatch.elapsed;
      _elapsedTime = '${elapsed.inHours.toString().padLeft(2, '0')}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
      notifyListeners();
    });

    notifyListeners();

    final testedReflectors = _results.map((r) => r['foundWithReflector'] as String).toSet();
    final reflectorsToTest = ['B', 'C'].where((r) => !testedReflectors.contains(r)).toList();
    
    List<String> runOrder = [];
    if (reflectorsToTest.contains(_selectedReflector)) {
      runOrder.add(_selectedReflector);
      runOrder.addAll(reflectorsToTest.where((r) => r != _selectedReflector));
    } else {
      runOrder.addAll(reflectorsToTest);
    }

    for (final reflector in runOrder) {
      if (_isCancelled || _isPaused) break;
      await _runSimulationForReflector(reflector);
    }

    if (_isRunning) {
      stopSimulation();
    }
  }

  void _pauseForCandidate() {
    _isRunning = false;
    _isPaused = true;
    _stopwatch.stop();
    _timer?.cancel();
    _colorChangeTimer?.cancel();
    _statusMessage = 'Parada candidata trobada!';
    notifyListeners();
  }

  void stopSimulation() {
    if (!_isRunning && !_isPaused) return;
    _isCancelled = true;
    _isRunning = false;
    _isPaused = false;
    _stopwatch.stop();
    _timer?.cancel();
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _colorChangeTimer?.cancel();
    _rotorColors = List.generate(3, (_) => Colors.grey[700]!);

    if (_results.isEmpty) {
      _statusMessage = 'Cerca completada. No s\'han trobat parades.';
    } else {
      _statusMessage = 'Anàlisi finalitzada. S\'han trobat ${_results.length} parades.';
    }
    notifyListeners();
  }

  Future<void> _playBellSound() async {
    try {
      await _audioPlayer.play(AssetSource('audio/bell.mp3'));
    } catch (e) {
      developer.log('No es pot reproduir el so: $e', name: 'bombe.audio');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _streamSubscription?.cancel();
    _colorChangeTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

// Pantalla de la Bombe
class BombeScreen extends StatelessWidget {
  const BombeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BombeState>(
      builder: (context, bombeState, child) {
        return Scaffold(
          backgroundColor: Colors.grey[850],
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInputPanel(context, bombeState),
                  const SizedBox(height: 24),
                  _buildControlAndStatusPanel(context, bombeState),
                  const SizedBox(height: 24),
                  if (bombeState.errorMessage != null)
                    _buildErrorPanel(context, bombeState.errorMessage!),
                  _buildResultsPanel(context, bombeState),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputPanel(BuildContext context, BombeState state) {
    return Card(
      color: Colors.grey[900],
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dades per a l\'Anàlisi', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              onChanged: state.setCiphertext,
              enabled: !state.isRunning && !state.isPaused,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'monospace'),
              decoration: const InputDecoration(labelText: 'Text Xifrat'),
              minLines: 2, maxLines: 5,
              controller: TextEditingController(text: state.ciphertext)..selection = TextSelection.fromPosition(TextPosition(offset: state.ciphertext.length)),
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: state.setCrib,
              enabled: !state.isRunning && !state.isPaused,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'monospace'),
              decoration: const InputDecoration(labelText: 'Crib (Text pla conegut)'),
              minLines: 1, maxLines: 3,
               controller: TextEditingController(text: state.crib)..selection = TextSelection.fromPosition(TextPosition(offset: state.crib.length)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlAndStatusPanel(BuildContext context, BombeState state) {
    return Card(
      color: Colors.grey[900],
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusIndicator(state),
                if (!state.isRunning)
                  ElevatedButton.icon(
                    icon: Icon(state.isPaused ? Icons.skip_next : Icons.play_arrow),
                    onPressed: (state.crib.isEmpty || state.ciphertext.isEmpty) ? null : state.startOrResumeSimulation,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                    label: Text(state.isPaused ? 'Continua Anàlisi' : 'Començar Anàlisi'),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.stop_circle_outlined, color: Colors.red, size: 40),
                    onPressed: state.stopSimulation,
                    tooltip: 'Aturar Simulació',
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDrumScramblers(state),
            const SizedBox(height: 20),
            _buildProgressDisplay(state),
            const SizedBox(height: 10),
            Text(state.statusMessage, textAlign: TextAlign.center, style: TextStyle(color: state.results.isNotEmpty ? Colors.greenAccent : Colors.white70, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BombeState state) {
    Color lightColor;
    String statusText;

    if (state.isRunning) {
      lightColor = Colors.yellow;
      statusText = 'EN MARXA';
    } else if (state.isPaused) {
      lightColor = Colors.greenAccent;
      statusText = 'PAUSAT';
    } else if (state.results.isNotEmpty) {
      lightColor = Colors.green;
      statusText = 'FINALITZAT';
    } else if (state.isCancelled) {
       lightColor = Colors.orange;
      statusText = 'ATURAT';
    } else {
      lightColor = Colors.red;
      statusText = 'INACTIU';
    }

    return Column(
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: lightColor,
            boxShadow: [BoxShadow(color: lightColor.withAlpha((255 * 0.7).round()), blurRadius: 15, spreadRadius: 3)],
          ),
        ),
        const SizedBox(height: 8),
        Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDrumScramblers(BombeState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (i) {
        final color = state.rotorColors[i];
        final darkerColor = Color.lerp(color, Colors.black, 0.6)!;
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey[600]!, width: 3),
            gradient: RadialGradient(
              colors: [color, darkerColor],
              stops: const [0.3, 1.0],
              center: const Alignment(0.0, -0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha((255 * 0.6).round()),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[400]!, width: 2),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildProgressDisplay(BombeState state) {
    final numberFormatter = NumberFormat('#,##0', 'es_ES');
    if (!state.isRunning && !state.isPaused && state.combinationsChecked == 0) return const SizedBox.shrink();
    
    return Column(
      children: [
         Text(
            state.elapsedTime,
            style: const TextStyle(color: Colors.white70, fontSize: 24, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
        Text(
          '${numberFormatter.format(state.combinationsChecked)} / ${numberFormatter.format(state.totalCombinations)}',
          style: const TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'monospace'),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: state.totalCombinations > 0 ? state.combinationsChecked / state.totalCombinations : 0,
          backgroundColor: Colors.grey[700],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellow),
        ),
      ],
    );
  }

  Widget _buildErrorPanel(BuildContext context, String errorMessage) {
    return Card(
      color: Colors.red[900]?.withAlpha((255 * 0.8).round()),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildResultsPanel(BuildContext context, BombeState state) {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resultats (Parades Candidates)', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (state.results.isEmpty)
              const Text('Esperant resultats...', style: TextStyle(color: Colors.white70))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.results.length,
                itemBuilder: (context, index) => _buildResultTile(context, state, state.results[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultTile(BuildContext context, BombeState bombeState, Map<String, dynamic> result) {
    final rotorOrder = result['rotorOrder'] as List<String>;
    final startPositions = (result['startPositions'] as List<int>).map((p) => String.fromCharCode('A'.codeUnitAt(0) + p)).toList();
    final encryptedCrib = result['encryptedCrib'] as String;
    final foundWithReflector = result['foundWithReflector'] as String;
    final relevantCiphertext = bombeState.ciphertext.substring(0, bombeState.crib.length);

    return Card(
      color: Colors.green[900]?.withAlpha((255 * 0.5).round()),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        initiallyExpanded: true,
        iconColor: Colors.greenAccent,
        collapsedIconColor: Colors.white70,
        title: Text('Config: ${rotorOrder.join('-')}  Pos: ${startPositions.join('-')}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('Reflector: $foundWithReflector', style: const TextStyle(color: Colors.white70)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Informe de la Parada:', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                _buildComparisonRow('Xifrat Original:', relevantCiphertext),
                const SizedBox(height: 8),
                _buildComparisonRow('Xifrat Candidat:', encryptedCrib),
                const Divider(color: Colors.white30, height: 24),
                const Text('Compara el text xifrat candidat amb l\'original per a deduir les connexions del panell.', style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.settings_input_component, size: 18),
                    label: const Text('Provar a l\'Enigma'),
                    onPressed: () {
                      final enigmaState = Provider.of<EnigmaState>(context, listen: false);
                      enigmaState.setRotor(0, rotorOrder[0]);
                      enigmaState.setRotor(1, rotorOrder[1]);
                      enigmaState.setRotor(2, rotorOrder[2]);
                      enigmaState.setRotorPosition(0, startPositions[0].codeUnitAt(0) - 'A'.codeUnitAt(0));
                      enigmaState.setRotorPosition(1, startPositions[1].codeUnitAt(0) - 'A'.codeUnitAt(0));
                      enigmaState.setRotorPosition(2, startPositions[2].codeUnitAt(0) - 'A'.codeUnitAt(0));
                      enigmaState.setReflector(foundWithReflector);
                      enigmaState.setInputText(bombeState.crib);
                      DefaultTabController.of(context).animateTo(0);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
