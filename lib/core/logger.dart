import 'dart:io';

/// 日志级别；数值越大越严重。低于 [AppLogger.minLevel] 的条目会被丢弃。
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}

extension LogLevelX on LogLevel {
  String get label => name.toUpperCase();
  int get value => index;
}

/// 单条日志记录。
class LogEntry {
  const LogEntry({
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
    this.stack,
  });

  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;
  final Object? error;
  final StackTrace? stack;

  /// 单行文本（时间 [级别][标签] 消息 [err]）。
  String toLine() {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    final base = '[$h:$m:$s][${level.label}][$tag] $message';
    return error != null ? '$base | err: $error' : base;
  }
}

/// 轻量、零依赖的日志系统。
///
/// 特性：
///  - 内存 ring buffer（保留最新 [maxBuffer] 条），可用 [exportText] 导出所有记录。
///  - 可选文件 sink：[attachFile] 后所有条目追加写入（移动 / 桌面可用；Web 不适用）。
///    文件超过 1MB 会自动截断，避免无限增长。
///  - 控制台输出仅在非 release 模式（`dart.vm.product=false`）下生效。
///
/// 用法：
/// ```dart
/// log.d('TDLib', 'client created');
/// log.e('Auth', 'login failed', e, stack);
/// ```
class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  /// 低于此级别的条目被忽略。
  LogLevel minLevel = LogLevel.debug;

  /// 总开关。
  bool enabled = true;

  static const int maxBuffer = 1000;
  final List<LogEntry> _buffer = [];

  File? _file;

  /// 当前附加的日志文件（可能为 null）。供 UI 读取 / 展示文件路径。
  File? get file => _file;

  /// 附加一个日志文件（追加写入）。建议 app 启动时用 path_provider 取得目录后调用。
  Future<void> attachFile(File file) async {
    _file = file;
    try {
      if (await file.exists() && await file.length() > 1024 * 1024) {
        await file.writeAsString('');
      }
    } catch (_) {
      // 文件不可用不阻塞 App
    }
  }

  /// 清空内存 buffer（不影响已写入的文件）。
  void clearBuffer() => _buffer.clear();

  /// 只读快照。
  List<LogEntry> get buffer => List.unmodifiable(_buffer);

  /// 导出为纯文本（用于复制 / 分享）。
  String exportText() => _buffer.map((e) => e.toLine()).join('\n');

  void v(String tag, String message) => _emit(LogLevel.verbose, tag, message);
  void d(String tag, String message) => _emit(LogLevel.debug, tag, message);
  void i(String tag, String message) => _emit(LogLevel.info, tag, message);
  void w(String tag, String message) => _emit(LogLevel.warning, tag, message);
  void e(String tag, String message, [Object? error, StackTrace? stack]) =>
      _emit(LogLevel.error, tag, message, error, stack);

  void _emit(
    LogLevel level,
    String tag,
    String message, [
    Object? error,
    StackTrace? stack,
  ]) {
    if (!enabled || level.value < minLevel.value) return;

    final entry = LogEntry(
      time: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error,
      stack: stack,
    );
    _buffer.add(entry);
    if (_buffer.length > maxBuffer) _buffer.removeAt(0);

    const isRelease = bool.fromEnvironment('dart.vm.product');
    if (!isRelease) {
      // 直接 print，避免 debugPrint 的节流影响排障。
      // ignore: avoid_print
      print(entry.toLine());
    }

    if (_file != null) {
      try {
        final line = entry.toLine() +
            (stack != null ? '\n${stack.toString().trim()}' : '') +
            '\n';
        _file!.writeAsStringSync(line, mode: FileMode.append);
      } catch (_) {
        // 忽略写入失败
      }
    }
  }
}

/// 全局日志单例。
final log = AppLogger.instance;
