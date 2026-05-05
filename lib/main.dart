import 'package:flutter/widgets.dart';

import 'app.dart';
import 'data/services/local_pos_backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final backend = await LocalPosBackend.bootstrap();
  runApp(PosApp(backend: backend));
}
