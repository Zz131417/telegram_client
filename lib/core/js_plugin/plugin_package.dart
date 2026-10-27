import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// 插件清单（来自包内 `config.json`）。
class PluginManifest {
  const PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    this.description = '',
    this.entry = 'scripts/main.js',
    this.minApi = '1.0',
  });

  final String id;
  final String name;
  final String version;
  final String description;
  final String entry; // 入口脚本相对路径
  final String minApi; // 要求的最低 td API 版本

  factory PluginManifest.fromJson(Map<String, dynamic> j) => PluginManifest(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? 'Untitled').toString(),
        version: (j['version'] ?? '0.0.0').toString(),
        description: (j['description'] ?? '').toString(),
        entry: (j['entry'] ?? 'scripts/main.js').toString(),
        minApi: (j['minApi'] ?? '1.0').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'version': version,
        'description': description,
        'entry': entry,
        'minApi': minApi,
      };
}

/// 一个解析后的插件包。来源可以是 `.zip` 字节或已解压的目录。
///
/// 规定的插件包结构（根目录下）：
/// ```
/// <plugin>.zip
/// ├── config.json        # 元信息（必填）
/// ├── scripts/           # JS 源码（必填，入口 scripts/main.js）
/// │   └── main.js
/// ├── image/             # 图标 / 封面（可选，UI 展示用）
/// └── lib/               # 原生库（可选，预留：当前不自动加载）
/// ```
class PluginPackage {
  PluginPackage({
    required this.manifest,
    required this.entryScript,
    this.imagePath,
  });

  final PluginManifest manifest;
  final String entryScript; // 入口脚本源码（已读取为字符串）
  final String? imagePath; // 相对路径，指向 image/ 下的图标（仅元数据）

  /// 从解压后的目录加载。
  factory PluginPackage.fromDirectory(Directory dir) {
    final cfgFile = File('${dir.path}/config.json');
    if (!cfgFile.existsSync()) {
      throw const FormatException('插件缺少 config.json');
    }
    final manifest = PluginManifest.fromJson(
      jsonDecode(cfgFile.readAsStringSync()) as Map<String, dynamic>,
    );
    final entryFile = File('${dir.path}/${manifest.entry}');
    if (!entryFile.existsSync()) {
      throw FormatException('入口脚本不存在: ${manifest.entry}');
    }
    final imagePath = _firstImage('${dir.path}/image');
    return PluginPackage(
      manifest: manifest,
      entryScript: entryFile.readAsStringSync(),
      imagePath: imagePath,
    );
  }

  /// 从 `.zip` 字节加载。
  factory PluginPackage.fromZip(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final cfg = archive.findFile('config.json');
    if (cfg == null || cfg.isFile == false) {
      throw const FormatException('插件 zip 缺少 config.json');
    }
    final manifest = PluginManifest.fromJson(
      jsonDecode(utf8.decode(cfg.content)) as Map<String, dynamic>,
    );
    final entry = archive.findFile(manifest.entry);
    if (entry == null || entry.isFile == false) {
      throw FormatException('入口脚本不存在: ${manifest.entry}');
    }
    String? imagePath;
    for (final f in archive.files) {
      if (f.isFile && f.name.startsWith('image/')) {
        final ext = f.name.split('.').last.toLowerCase();
        if (const ['png', 'jpg', 'jpeg', 'webp'].contains(ext)) {
          imagePath = f.name;
          break;
        }
      }
    }
    return PluginPackage(
      manifest: manifest,
      entryScript: utf8.decode(entry.content),
      imagePath: imagePath,
    );
  }

  /// 从本地文件加载：按扩展名判断是 zip 还是目录。
  factory PluginPackage.fromFile(String path) {
    if (path.toLowerCase().endsWith('.zip')) {
      return PluginPackage.fromZip(File(path).readAsBytesSync());
    }
    return PluginPackage.fromDirectory(Directory(path));
  }

  static String? _firstImage(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return null;
    for (final f in dir.listSync().whereType<File>()) {
      final ext = f.path.split('.').last.toLowerCase();
      if (const ['png', 'jpg', 'jpeg', 'webp'].contains(ext)) {
        return 'image/${f.path.split('/').last}';
      }
    }
    return null;
  }
}
