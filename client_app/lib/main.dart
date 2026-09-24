import 'package:flutter/material.dart';
import 'package:inhouse_codepush/inhouse_codepush.dart';

// Change these to ship an over-the-air patch
const String kAppLabel = '⚡ Client App - V2.0 (OTA Patched!) 🚀';
const Color kAppColor = Color(0xFF0077B6); // Ocean Cerulean Blue

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  InhouseCodePush.init(
    serverUrls: ['http://10.0.2.2:8080', 'http://localhost:8080'],
    appId: 'com.test.client_app',
    releaseVersion: '1.0.0',
    onPatchReady: (patchNumber) {
      debugPrint(
        '==> New patch #$patchNumber downloaded and ready for next restart!',
      );
    },
  );
  runApp(const ClientApp());
}

class ClientApp extends StatelessWidget {
  const ClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'priyanka App Code Push',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kAppColor),
        useMaterial3: true,
      ),
      home: const ClientHomePage(),
    );
  }
}

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppColor,
        foregroundColor: Colors.white,
        title: const Text('lodu App - Inhouse CodePush V2.0'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: kAppColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  kAppLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade600, width: 1.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Live mohirt Update Active!',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Imported via inhouse_codepush package!',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.displayLarge
                    ?.copyWith(color: kAppColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kAppColor,
        foregroundColor: Colors.white,
        onPressed: () => setState(() => _counter++),
        child: const Icon(Icons.rocket_launch),
      ),
    );
  }
}
