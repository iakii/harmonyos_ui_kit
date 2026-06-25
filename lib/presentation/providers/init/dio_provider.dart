import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rohos_app/core/network/dio_client.dart';

/// Dio 实例 Provider —— 单例，应用全局共享。
///
/// 使用方式：
/// ```dart
/// final dio = ref.read(dioProvider);
/// final response = await dio.get('/path');
/// ```
final dioClientProvider = Provider<DioClient>((ref) {
  final client = DioClient();
  ref.onDispose(() => client.dispose());
  return client;
});

/// 原始 Dio 实例（便捷访问）。
final dioProvider = Provider<Dio>((ref) {
  return ref.watch(dioClientProvider).dio;
});
