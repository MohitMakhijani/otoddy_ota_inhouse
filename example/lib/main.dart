import 'package:flutter/material.dart';
import 'package:inhouse_codepush/inhouse_codepush.dart';

// ===========================================================================
//  CHANGE THESE TWO LINES + rebuild to ship an over-the-air patch.
//  The label and color are exactly what you'll watch flip on the device after
//  a patch lands — no store release involved.
// ===========================================================================
const String kBuildLabel = '🚀 V2.0: Updated Over The Air! ✨';
const Color kBuildColor = Color(0xFF00C853); // Emerald Green

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  InhouseCodePush.init(
    serverUrls: [
      'http://10.0.2.2:8080',
      'http://localhost:8080',
    ],
    appId: 'com.example.codepush_demo',
    releaseVersion: '1.0.0',
  );
  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'In-House Code Push Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kBuildColor),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBuildColor,
        foregroundColor: Colors.white,
        title: const Text('In-House Code Push'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: kBuildColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                kBuildLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle, color: Color(0xFF00C853), size: 20),
                SizedBox(width: 6),
                Text(
                  'OTA Code Push Active & Verified!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00C853),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Push a patch, then fully close and reopen the app twice —\n'
                'launch one downloads it, launch two runs it.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),
            Text('$_counter', style: Theme.of(context).textTheme.displayMedium),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kBuildColor,
        foregroundColor: Colors.white,
        onPressed: () => setState(() => _counter++),
        child: const Icon(Icons.add),
      ),
    );
  }
}
