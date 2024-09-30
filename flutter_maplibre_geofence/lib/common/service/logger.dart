import 'package:logger/logger.dart';

class FTALogger {
  static final Logger _logger = Logger();

  static void init() {
    // set the log level
    Logger.level = Level.debug;
  }

  static void log(String message) {
    _logger.d(message);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
