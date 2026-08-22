enum TuringDirection { left, right, stay }

class TuringTransition {
  final String currentState;
  final String currentSymbol;
  final String newState;
  final String newSymbol;
  final TuringDirection direction;

  TuringTransition({
    required this.currentState,
    required this.currentSymbol,
    required this.newState,
    required this.newSymbol,
    required this.direction,
  });

  @override
  String toString() {
    return '($currentState, $currentSymbol) -> ($newState, $newSymbol, $direction)';
  }
}

class TuringMachine {
  late List<String> _tape;
  late int _headPosition;
  late String _currentState;
  final Map<String, TuringTransition> _transitionMap;
  final List<TuringTransition> transitions;
  final String _initialState;
  final String _acceptState;
  final String _blankSymbol;

  TuringMachine({
    required this.transitions,
    required String initialState,
    required String acceptState,
    String blankSymbol = 'B',
  })  : _transitionMap = {
          for (var t in transitions) '${t.currentState}_${t.currentSymbol}': t
        },
        _initialState = initialState,
        _acceptState = acceptState,
        _blankSymbol = blankSymbol;

  static List<TuringTransition> parseTransitions(String rules) {
    final List<TuringTransition> transitions = [];
    final lines = rules.split('\n').where((line) => line.trim().isNotEmpty);
    for (var line in lines) {
      final parts = line.split(',').map((p) => p.trim()).toList();
      if (parts.length == 5) {
        final direction = TuringDirection.values.firstWhere(
          (d) => d.name.toUpperCase() == parts[4].toUpperCase() || d.name.substring(0,1).toUpperCase() == parts[4].toUpperCase(),
          orElse: () => TuringDirection.stay,
        );
        transitions.add(TuringTransition(
          currentState: parts[0],
          currentSymbol: parts[1],
          newState: parts[2],
          newSymbol: parts[3],
          direction: direction,
        ));
      }
    }
    return transitions;
  }


  void initialize(String input) {
    _tape = input.split('');
    if (_tape.isEmpty) {
      _tape.add(_blankSymbol);
    }
    _headPosition = 0;
    _currentState = _initialState;
  }

  String get tapeString => _tape.join();
  int get headPosition => _headPosition;
  String get currentState => _currentState;
  bool get isHalted => _currentState == _acceptState;

  void step() {
    if (isHalted) return;

    if (_headPosition < 0) {
      _tape.insert(0, _blankSymbol);
      _headPosition = 0;
    } else if (_headPosition >= _tape.length) {
      _tape.add(_blankSymbol);
    }

    final String currentSymbol = _tape[_headPosition];
    final String transitionKey = '${_currentState}_$currentSymbol';
    final TuringTransition? transition = _transitionMap[transitionKey];

    if (transition != null) {
      _tape[_headPosition] = transition.newSymbol;
      _currentState = transition.newState;
      switch (transition.direction) {
        case TuringDirection.left:
          _headPosition--;
          break;
        case TuringDirection.right:
          _headPosition++;
          break;
        case TuringDirection.stay:
          break;
      }
    } else {
      _currentState = _acceptState;
    }
  }
}
