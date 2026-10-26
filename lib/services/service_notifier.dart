import 'package:flutter/material.dart';

import 'td_service.dart';

/// 让登录界面可在运行时替换底层 [TdService]（Mock 预览 ↔ 真实 TDLib），
/// 并通过 ChangeNotifier 通知依赖方（如 ChatsProvider）重建。
class ServiceNotifier extends ChangeNotifier {
  ServiceNotifier(this._service);

  TdService _service;
  TdService get service => _service;

  set service(TdService s) {
    if (identical(_service, s)) return;
    _service = s;
    notifyListeners();
  }
}
