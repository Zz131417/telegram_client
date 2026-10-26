import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

// FFI 绑定到官方 TDLib 的 JSON 客户端 C 接口（td_json_client.h）。
// 这是「零第三方 TDLib 封装」的直接调用层，避免任何会拖入 native_prebuilt/hooks
// 的依赖，从而保证各平台 `flutter pub get` 与编译都干净通过。
//
// 原生库（libtdjson）仅在运行时加载；加载失败不影响 App 启动（调用方会优雅降级）。

typedef _CreateNative = Pointer<Void> Function();
typedef _Create = Pointer<Void> Function();

typedef _SendNative = Void Function(Pointer<Void>, Pointer<Utf8>);
typedef _Send = void Function(Pointer<Void>, Pointer<Utf8>);

typedef _ReceiveNative = Pointer<Utf8> Function(Pointer<Void>, Double);
typedef _Receive = Pointer<Utf8> Function(Pointer<Void>, double);

typedef _DestroyNative = Void Function(Pointer<Void>);
typedef _Destroy = void Function(Pointer<Void>);

/// 一个 TDLib JSON 客户端的底层封装。
class FfiTdClient {
  FfiTdClient._(this._lib);

  final DynamicLibrary _lib;
  late final Pointer<Void> _client;
  late final _Send _send;
  late final _Receive _receive;
  late final _Destroy _destroy;

  bool _running = false;
  final Map<String, Completer<Map<String, dynamic>>> _pending = {};
  int _extraSeq = 0;

  /// 按平台加载原生 libtdjson。
  ///
  /// 策略：非 Android 平台先尝试从「可执行文件所在目录」加载（让自带原生库的
  /// 桌面/移动自包含包直接可用），失败再回退到系统默认搜索。Android 直接按名
  /// 加载即可（APK 的 lib/<abi>/ 会被自动加入搜索路径）。
  static DynamicLibrary loadLibrary() {
    final name = Platform.isWindows
        ? 'tdjson.dll'
        : Platform.isIOS || Platform.isMacOS
            ? 'libtdjson.dylib'
            : 'libtdjson.so';
    if (Platform.isAndroid) {
      return DynamicLibrary.open(name);
    }
    try {
      final dir = File(Platform.resolvedExecutable).parent.path;
      return DynamicLibrary.open('$dir/$name');
    } catch (_) {
      return DynamicLibrary.open(name);
    }
  }

  /// 创建客户端并绑定 C 函数。
  factory FfiTdClient.create() {
    final lib = loadLibrary();
    final client = FfiTdClient._(lib);
    client._send = lib.lookupFunction<_SendNative, _Send>('td_json_client_send');
    client._receive =
        lib.lookupFunction<_ReceiveNative, _Receive>('td_json_client_receive');
    client._destroy =
        lib.lookupFunction<_DestroyNative, _Destroy>('td_json_client_destroy');
    final create =
        lib.lookupFunction<_CreateNative, _Create>('td_json_client_create');
    client._client = create();
    return client;
  }

  /// 启动接收循环。update 回调收到所有服务端推送；请求的响应按 @extra 匹配。
  /// 使用 timeout=0 的非阻塞轮询 + 让出事件循环，避免阻塞 UI 线程。
  void start(Function(Map<String, dynamic>) onUpdate) {
    _running = true;
    _loop(onUpdate);
  }

  Future<void> _loop(Function(Map<String, dynamic>) onUpdate) async {
    while (_running) {
      final p = _receive(_client, 0.0);
      if (p.address != 0) {
        final str = p.toDartString(); // 立即复制（TDLib 字符串下次调用即失效）
        _dispatch(jsonDecode(str) as Map<String, dynamic>, onUpdate);
      }
      // 让出事件循环，保持 UI 流畅（每轮 ~10ms 间隔）。
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  void _dispatch(
    Map<String, dynamic> msg,
    Function(Map<String, dynamic>) onUpdate,
  ) {
    final extra = msg['@extra'];
    if (extra is String && _pending.containsKey(extra)) {
      _pending.remove(extra)!.complete(msg);
      return;
    }
    onUpdate(msg);
  }

  /// 发送一个请求并等待其响应。request 会自动附带唯一 @extra。
  Future<Map<String, dynamic>> send(Map<String, dynamic> request) {
    final extra = 'mc-${++_extraSeq}';
    request['@extra'] = extra;
    final completer = Completer<Map<String, dynamic>>();
    _pending[extra] = completer;
    final jsonStr = jsonEncode(request);
    final ptr = jsonStr.toNativeUtf8();
    _send(_client, ptr);
    malloc.free(ptr);
    return completer.future;
  }

  void dispose() {
    _running = false;
    _pending.clear();
    _destroy(_client);
  }
}
