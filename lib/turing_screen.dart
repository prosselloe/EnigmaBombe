import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'turing_logic/turing_machine.dart';

// --- Model de Dades per a Programes Predefinits ---
class TuringProgram {
  final String name;
  final String description;
  final String initialTape;
  final String rules;

  const TuringProgram({
    required this.name,
    required this.description,
    required this.initialTape,
    required this.rules,
  });
}

// --- Biblioteca de Programes ---
final List<TuringProgram> turingPrograms = [
  const TuringProgram(
    name: 'Inversor Binari',
    description: 'Inverteix una cadena binària (canvia 0s per 1s i viceversa).',
    initialTape: '01101',
    rules:
        'q0,0,q0,1,R\n'
        'q0,1,q0,0,R\n'
        'q0,B,qf,B,S',
  ),
  const TuringProgram(
    name: 'Suma Unària',
    description: 'Suma dos nombres en notació unària (ex: \'11+111\' -> \'11111\').',
    initialTape: '11+111',
    rules:
      'q0,1,q0,1,R\n'
      'q0,+,q1,1,R\n'
      'q1,1,q1,1,R\n'
      'q1,B,q2,B,L\n'
      'q2,1,qf,B,S',
  ),
  const TuringProgram(
    name: 'Castor Ocupat (3 estats)',
    description: 'Un exemple clàssic que escriu sis 1s abans de parar. Prova un repte d\'optimització!',
    initialTape: '0',
    rules:
        'a,0,b,1,R\n'
        'a,1,h,1,L\n'
        'b,0,c,0,R\n'
        'b,1,b,1,R\n'
        'c,0,c,1,L\n'
        'c,1,a,1,L',
  ),
   const TuringProgram(
    name: 'Generador de Palíndroms',
    description: 'Duplica una cadena binària per crear un palíndrom (ex: \'110\' -> \'110011\').',
    initialTape: '110',
    rules:
      'q0,0,q1,B,R\n' 'q0,1,q2,B,R\n' 'q0,B,qf,B,S\n'
      'q1,0,q1,0,R\n' 'q1,1,q1,1,R\n' 'q1,B,q3,0,L\n'
      'q2,0,q2,0,R\n' 'q2,1,q2,1,R\n' 'q2,B,q4,1,L\n'
      'q3,0,q3,0,L\n' 'q3,1,q3,1,L\n' 'q3,B,q0,B,R\n'
      'q4,0,q4,0,L\n' 'q4,1,q4,1,L\n' 'q4,B,q0,B,R',
  ),
];


// --- Gestió de l'Estat ---
class TuringMachineState with ChangeNotifier {
  late TuringMachine _turingMachine;
  final TextEditingController tapeController = TextEditingController();
  final TextEditingController rulesController = TextEditingController();
  bool _isRunning = false;
  Timer? _timer;
  String _currentProgramName = 'Personalitzat';

  // Getters
  TuringMachine get machine => _turingMachine;
  bool get isRunning => _isRunning;
  String get currentProgramName => _currentProgramName;
  String get tape => _turingMachine.tapeString;
  int get headPosition => _turingMachine.headPosition;
  String get currentState => _turingMachine.currentState;
  bool get isHalted => _turingMachine.isHalted;
  List<TuringTransition> get transitions => _turingMachine.transitions;
  

  TuringMachineState() {
    loadProgram(turingPrograms.first);
  }

  void loadProgram(TuringProgram program) {
    _currentProgramName = program.name;
    tapeController.text = program.initialTape;
    rulesController.text = program.rules;
    _initializeMachine();
    notifyListeners();
  }

  void setCustom() {
      _currentProgramName = 'Personalitzat';
      notifyListeners();
  }

  void _initializeMachine() {
    try {
      final transitions = TuringMachine.parseTransitions(rulesController.text);
      _turingMachine = TuringMachine(
        transitions: transitions,
        initialState: 'q0',
        acceptState: 'qf',
        blankSymbol: 'B',
      );
      _turingMachine.initialize(tapeController.text);
    } catch (e, s) {
      developer.log(
        'Error inicialitzant la màquina de Turing',
        name: 'turing.machine.init',
        error: e,
        stackTrace: s,
      );
       _turingMachine = TuringMachine(transitions: [], initialState: 'q0', acceptState: 'qf');
      _turingMachine.initialize('');
    }
    notifyListeners();
  }

  void _step() {
    if (!_turingMachine.isHalted) {
      _turingMachine.step();
      notifyListeners();
    }
    if (_turingMachine.isHalted) {
      _stopRun();
    }
  }

  void run() {
    if (_isRunning) return;
    _isRunning = true;
    notifyListeners();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_turingMachine.isHalted) {
        _stopRun();
      } else {
        _step();
      }
    });
  }

  void _stopRun() {
    _timer?.cancel();
    if (_isRunning) {
      _isRunning = false;
      notifyListeners();
    }
  }

  void reset() {
    _stopRun();
    _initializeMachine();
  }

  @override
  void dispose() {
    _timer?.cancel();
    tapeController.dispose();
    rulesController.dispose();
    super.dispose();
  }
}

// --- Interfície d'Usuari ---
class TuringScreen extends StatelessWidget {
  const TuringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TuringMachineState(),
      child: Consumer<TuringMachineState>(
        builder: (context, state, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Simulador de Màquina de Turing', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.yellow)),
                const SizedBox(height: 20),
                _buildProgramSelector(context, state),
                const SizedBox(height: 20),
                _buildControls(state),
                const SizedBox(height: 30),
                _buildTape(state),
                const SizedBox(height: 30),
                _buildStateInfo(state),
                const SizedBox(height: 20),
                _buildTransitionsTable(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgramSelector(BuildContext context, TuringMachineState state) {
    final isCustom = state.currentProgramName == 'Personalitzat';
    final currentProgram = turingPrograms.firstWhere((p) => p.name == state.currentProgramName, orElse: () => turingPrograms.first);

    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Programa de Prova', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 20),
                  Expanded(
                    child: DropdownButton<String>(
                      value: state.currentProgramName,
                      isExpanded: true,
                      dropdownColor: Colors.grey[800],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      items: [
                        ...turingPrograms.map((program) => DropdownMenuItem(
                              value: program.name,
                              child: Text(program.name, overflow: TextOverflow.ellipsis),
                            )),
                        const DropdownMenuItem(
                          value: 'Personalitzat',
                          child: Text('Personalitzat'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == 'Personalitzat') {
                          state.setCustom();
                        } else if (value != null) {
                          final program = turingPrograms.firstWhere((p) => p.name == value);
                          state.loadProgram(program);
                        }
                      },
                    ),
                  ),
                ],
            ),
             const SizedBox(height: 10),
             if (!isCustom)
                Text(currentProgram.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),

          ],
        ),
      ),
    );
  }

  Widget _buildControls(TuringMachineState state) {
      final isCustom = state.currentProgramName == 'Personalitzat';
    return Column(
      children: [
        TextField(
          controller: state.tapeController,
          readOnly: !isCustom,
          onChanged: (value) => state.reset(),
          decoration: InputDecoration(
            labelText: 'Entrada de la Cinta',
            border: const OutlineInputBorder(),
             filled: !isCustom,
            fillColor: !isCustom ? Colors.grey[800] : null,
          ),
          style: TextStyle(color: isCustom ? Colors.white : Colors.grey[400], fontFamily: 'monospace'),
        ),
        const SizedBox(height: 16),
        if (isCustom) ...[
             TextField(
                controller: state.rulesController,
                maxLines: 5,
                 onChanged: (value) => state.reset(),
                decoration: const InputDecoration(
                    labelText: 'Regles de Transició (estat,símbol,nou_estat,nou_símbol,direcció)',
                    border: OutlineInputBorder(),
                    helperText: 'Ex: q0,0,q0,1,R\nEx: q0,B,qf,B,S',
                ),
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
        ],
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            ElevatedButton.icon(icon: const Icon(Icons.play_arrow), label: const Text('Executar'), onPressed: state.isRunning ? null : state.run, style: ElevatedButton.styleFrom(backgroundColor: Colors.green)),
            ElevatedButton.icon(icon: const Icon(Icons.stop), label: const Text('Parar'), onPressed: state.isRunning ? state._stopRun : null),
            ElevatedButton.icon(icon: const Icon(Icons.skip_next), label: const Text('Pas'), onPressed: state.isRunning || state.isHalted ? null : state._step),
            ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Reiniciar'), onPressed: state.reset, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange)),
          ],
        ),
      ],
    );
  }

  Widget _buildTape(TuringMachineState state) {
    List<String> tape = state.tape.split('');
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(77),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!)
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tape.length, (index) {
            bool isHead = index == state.headPosition;
            return Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isHead ? Colors.yellow : Colors.grey[800],
                border: Border.all(color: Colors.grey[600]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  tape[index],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isHead ? Colors.black : Colors.white,
                    fontFamily: 'monospace'
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStateInfo(TuringMachineState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _infoCard('Estat Actual', state.currentState),
        _infoCard('Posició del Capçal', state.headPosition.toString()),
        _infoCard('Finalitzat', state.isHalted ? 'Sí' : 'No', color: state.isHalted ? Colors.green : Colors.redAccent),
      ],
    );
  }

   Widget _buildTransitionsTable(BuildContext context, TuringMachineState state) {
    return Card(
        color: Colors.grey[900],
        child: ExpansionTile(
            title: const Text('Taula de Transicions Actives', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            initiallyExpanded: true,
            children: [
                DataTable(
                    columns: const [
                        DataColumn(label: Text('Estat Actual')),
                        DataColumn(label: Text('Símbol llegit')),
                        DataColumn(label: Text('Nou Estat')),
                        DataColumn(label: Text('Símbol escrit')),
                        DataColumn(label: Text('Moviment')),
                    ],
                    rows: state.transitions.map<DataRow>((t) {
                        return DataRow(
                            cells: [
                                DataCell(Text(t.currentState)),
                                DataCell(Text(t.currentSymbol)),
                                DataCell(Text(t.newState)),
                                DataCell(Text(t.newSymbol)),
                                DataCell(Text(t.direction.name.toUpperCase())),
                            ],
                        );
                    }).toList(),
                ),
            ],
        ),
    );
  }

  Widget _infoCard(String label, String value, {Color color = Colors.white}) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: Colors.yellow, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
