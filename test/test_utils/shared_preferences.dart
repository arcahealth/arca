import 'package:flutter/services.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

final class MockSharedPreferencesAsync()
    extends SharedPreferencesAsyncPlatform {
  final _internal = InMemorySharedPreferencesAsync.empty();
  final log = <MethodCall>[];

  @override
  Future<bool> clear(
    ClearPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) {
    log.add(MethodCall('clear', <Object>[...?parameters.filter.allowList]));
    return _internal.clear(parameters, options);
  }

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) {
    log.add(MethodCall('getBool', <String>[key]));
    return _internal.getBool(key, options);
  }

  @override
  Future<double?> getDouble(String key, SharedPreferencesOptions options) {
    log.add(MethodCall('getDouble', <String>[key]));
    return _internal.getDouble(key, options);
  }

  @override
  Future<int?> getInt(String key, SharedPreferencesOptions options) {
    log.add(MethodCall('getInt', <String>[key]));
    return _internal.getInt(key, options);
  }

  @override
  Future<Set<String>> getKeys(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) {
    log.add(MethodCall('getKeys', <String>[...?parameters.filter.allowList]));
    return _internal.getKeys(parameters, options);
  }

  @override
  Future<Map<String, Object>> getPreferences(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) {
    log.add(
      MethodCall('getPreferences', <Object>[...?parameters.filter.allowList]),
    );
    return _internal.getPreferences(parameters, options);
  }

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) {
    log.add(MethodCall('getString', <String>[key]));
    return _internal.getString(key, options);
  }

  @override
  Future<List<String>?> getStringList(
    String key,
    SharedPreferencesOptions options,
  ) {
    log.add(MethodCall('getStringList', <String>[key]));
    return _internal.getStringList(key, options);
  }

  @override
  Future<bool> setBool(
    String key,
    bool value,
    SharedPreferencesOptions options,
  ) {
    log.add(MethodCall('setBool', <Object>[key, value]));
    return _internal.setBool(key, value, options);
  }

  @override
  Future<bool> setDouble(
    String key,
    double value,
    SharedPreferencesOptions options,
  ) {
    log.add(MethodCall('setDouble', <Object>[key, value]));
    return _internal.setDouble(key, value, options);
  }

  @override
  Future<bool> setInt(String key, int value, SharedPreferencesOptions options) {
    log.add(MethodCall('setInt', <Object>[key, value]));
    return _internal.setInt(key, value, options);
  }

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) {
    log.add(MethodCall('setString', <Object>[key, value]));
    return _internal.setString(key, value, options);
  }

  @override
  Future<bool> setStringList(
    String key,
    List<String> value,
    SharedPreferencesOptions options,
  ) {
    log.add(MethodCall('setStringList', <Object>[key, value]));
    return _internal.setStringList(key, value, options);
  }
}
