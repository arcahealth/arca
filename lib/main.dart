import 'package:arca/app/app.dart';
import 'package:circuitry_flutter/circuitry_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    CircuitRegistry.instance.registerVmServiceExtensions();
  }

  runApp(const ArcaApp());
}
