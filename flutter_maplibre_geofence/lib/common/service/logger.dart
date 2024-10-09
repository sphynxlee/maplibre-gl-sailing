import 'package:logger/logger.dart';

class MapLogger {
  static final Logger _logger = Logger();
  static const String _tag = '====== GeoFence ======';

  static void init() {
    // set the log level
    Logger.level = Level.debug;
  }

  static void log(String message) {
    _logger.d('$_tag $message');
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e('$_tag $message', error: error, stackTrace: stackTrace);
  }
}
