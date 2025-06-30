class SessionData {
  static final SessionData _instance = SessionData._internal();
  factory SessionData() => _instance;
  SessionData._internal();

  List<Map<String, dynamic>> liveData = [];
  Set<int> liveIds = {};
}
