class Plugboard {
  final Map<String, String> _connections = {};

  void addConnection(String char1, String char2) {
    _connections[char1] = char2;
    _connections[char2] = char1;
  }

  void removeConnection(String char) {
    final connectedChar = _connections[char];
    if (connectedChar != null) {
      _connections.remove(char);
      _connections.remove(connectedChar);
    }
  }

  void clear() {
    _connections.clear();
  }

  String swap(String char) {
    return _connections[char] ?? char;
  }

  Map<String, String> get connections => Map.unmodifiable(_connections);
}
