import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:get_module/get_module.dart';

/// module scope
enum Scope {
  // run module at any mode.
  all,
  // run module only at debug mode.
  debug,
  // run module only at production mode and profile mode.
  production,
}

/// error handling method
enum ErrorHandle {
  // ignore error and log on console in debug mode.
  silence,
  // terminate module installation, and hand it over to GetModule
  throws,
  // retry until success
  retry,
}

/// Module
abstract class Module {
  late ModuleLoader moduleLoader;

  @protected
  @visibleForTesting
  Scope scope = Scope.all;

  @protected
  @visibleForTesting
  ErrorHandle errorHandle = ErrorHandle.throws;

  @protected
  @visibleForTesting
  int failCount = 0;

  int retries = 3;

  List<Type> dependencies = [];

  @visibleForTesting
  bool testingProductionMode = false;

  @protected
  bool get isDebug => !testingProductionMode && kDebugMode;

  FutureOr<void> install();

  Future<void> run() async {
    if (isDebug && scope == Scope.production) {
      log('$runtimeType module is production only, so ignored', name: 'Get Module');
      return;
    }

    if (!isDebug && scope == Scope.debug) {
      return;
    }

    try {
      await install();
    } catch (e) {
      failCount++;
      switch (errorHandle) {
        case ErrorHandle.silence:
          break;
        case ErrorHandle.throws:
          rethrow;
        case ErrorHandle.retry:
          if (failCount > retries) {
            rethrow;
          }
          await Future.delayed(const Duration(milliseconds: 100));
          await run();
          break;
      }
    }
  }

  Module get debugOnly {
    scope = Scope.debug;
    return this;
  }

  Module get productionOnly {
    scope = Scope.production;
    return this;
  }

  Module get silenceOnError {
    errorHandle = ErrorHandle.silence;
    return this;
  }

  Module get retryOnError {
    errorHandle = ErrorHandle.retry;
    return this;
  }
}
