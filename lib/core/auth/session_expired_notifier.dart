import 'dart:async';

/// Notifica cuando el SyncManager detecta HTTP 401 (token inválido).
class SessionExpiredNotifier {
  SessionExpiredNotifier._();

  static final SessionExpiredNotifier instance = SessionExpiredNotifier._();

  final StreamController<void> _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
