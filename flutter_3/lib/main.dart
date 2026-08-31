import 'dart:async';
import 'dart:math'; // Imported normally for pi, cos, sin without function name collisions
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

// Inlined Firebase Web Configuration for food-freshness-78e13
const firebaseWebOptions = FirebaseOptions(
  apiKey: 'AIzaSyBnAHVSqTjqgRWZG3vVyDldTV1r4ewdN2A',
  appId: '1:875181595702:web:ba8b4b0a4113fc7dad4c97',
  messagingSenderId: '875181595702',
  projectId: 'food-freshness-78e13',
  authDomain: 'food-freshness-78e13.firebaseapp.com',
  databaseURL: 'https://food-freshness-78e13-default-rtdb.asia-southeast1.firebasedatabase.app',
  storageBucket: 'food-freshness-78e13.firebasestorage.app',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool initialized = false;
  try {
    await Firebase.initializeApp(options: firebaseWebOptions);
    initialized = true;
  } catch (e) {
    debugPrint("Firebase init failed: $e");
  }
  runApp(MyApp(firebaseInitialized: initialized));
}

class MyApp extends StatelessWidget {
  final bool firebaseInitialized;
  const MyApp({super.key, required this.firebaseInitialized});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshGuard Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: DashboardPage(firebaseInitialized: firebaseInitialized),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final bool firebaseInitialized;
  const DashboardPage({super.key, required this.firebaseInitialized});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('/Fruit_Status');
  StreamSubscription? _dbSubscription;

  // Real-time parameters
  String _freshnessStatus = "loading...";
  double _weight = 0.0;
  double _mq135Ppm = 0.0;
  double _mq3Ppm = 0.0;
  double _temperature = 0.0;
  double _humidity = 0.0;

  bool _dbConnected = false;
  bool _localSimMode = false;
  String? _errorMessage;

  // Simple telemetry value storage list
  final List<double> _weightHistory = [];

  @override
  void initState() {
    super.initState();
    _dbConnected = widget.firebaseInitialized;
    if (_dbConnected) {
      _initializeRealtimeDataPipeline();
    } else {
      _errorMessage = "Firebase system initialization faulted on application boot.";
    }
  }

  void _initializeRealtimeDataPipeline() {
    _dbSubscription = _dbRef.onValue.listen((DatabaseEvent event) {
      if (_localSimMode) return; 

      final dataSnapshot = event.snapshot.value as Map<dynamic, dynamic>?;
      
      if (dataSnapshot != null) {
        setState(() {
          _dbConnected = true;
          _errorMessage = null;

          _freshnessStatus = (dataSnapshot['current_state'] ?? 'unknown').toString().toLowerCase().trim();
          _weight = double.tryParse(dataSnapshot['weight_g'].toString()) ?? 0.0;
          _mq135Ppm = double.tryParse(dataSnapshot['mq135_ppm'].toString()) ?? 0.0;
          _mq3Ppm = double.tryParse(dataSnapshot['mq3_ppm'].toString()) ?? 0.0;
          _temperature = double.tryParse(dataSnapshot['temperature_c'].toString()) ?? 0.0;
          _humidity = double.tryParse(dataSnapshot['humidity_pct'].toString()) ?? 0.0;

          _weightHistory.add(_weight);
          
          if (_weightHistory.length > 15) {
            _weightHistory.removeAt(0);
          }
        });
      }
    }, onError: (error) {
      setState(() {
        _dbConnected = false;
        _errorMessage = "Socket connection interrupted: $error";
      });
    });
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    super.dispose();
  }

  Color _getStatusColor() {
    switch (_freshnessStatus) {
      case "fresh":
        return const Color(0xFF10B981);
      case "ripening":
      case "moderate":
      case "warning":
        return const Color(0xFFF59E0B);
      case "spoilt":
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.security, color: Color(0xFF6366F1)),
            const SizedBox(width: 10),
            const Text(
              'FreshGuard',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 0.5, color: Colors.white),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _localSimMode 
                    ? const Color(0x1AFF9800) 
                    : (_dbConnected ? const Color(0x1A4CAF50) : const Color(0x1AF44336)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _localSimMode 
                      ? Colors.orange 
                      : (_dbConnected ? Colors.green : Colors.red),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _localSimMode 
                          ? Colors.orange 
                          : (_dbConnected ? Colors.green : Colors.red),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _localSimMode 
                        ? 'LOCAL SIM' 
                        : (_dbConnected ? 'CONNECTED' : 'DISCONNECTED'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _localSimMode 
                          ? Colors.orange 
                          : (_dbConnected ? Colors.green : Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x26FF5252), 
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x4DFF5252)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                        onPressed: () => setState(() => _errorMessage = null),
                      )
                    ],
                  ),
                ),
              isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildStatusCard(statusColor),
                              _buildGasGaugeCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildWeightHistoryCard(),
                              _buildSimulationPanel(),
                            ],
                          ),
                        )
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildStatusCard(statusColor),
                        const SizedBox(height: 8),
                        _buildGasGaugeCard(),
                        const SizedBox(height: 8),
                        _buildWeightHistoryCard(),
                        const SizedBox(height: 8),
                        _buildSimulationPanel(),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(Color color) {
    String message = "Awaiting live telemetry matrix packet...";
    IconData statusIcon = Icons.help_outline;
    
    if (_freshnessStatus == "fresh") {
      message = "Optimal condition storage parameter verified. Safe for processing.";
      statusIcon = Icons.check_circle_outline;
    } else if (_freshnessStatus == "ripening" || _freshnessStatus == "moderate" || _freshnessStatus == "warning") {
      message = "Ripening markers detected. Accelerating enzymatic metrics noticed.";
      statusIcon = Icons.warning_amber_rounded;
    } else if (_freshnessStatus == "spoilt") {
      message = "High hazard decomposition compounds tracked. Disposal advised.";
      statusIcon = Icons.dangerous_outlined;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Theme.of(context).cardColor, const Color(0x991E293B)], 
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FRESHNESS ANALYSIS STATUS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(statusIcon, color: color, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _freshnessStatus.toUpperCase(),
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(message, style: const TextStyle(fontSize: 13, color: Colors.white70, height: 1.3)),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildGasGaugeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ENVIRONMENTAL SENSOR CLUSTER',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.blueGrey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRadialGauge("MQ-135 (CO2)", _mq135Ppm, 0.0, 1000.0, "ppm", Colors.purpleAccent),
                _buildRadialGauge("MQ-3 (Ethanol)", _mq3Ppm, 0.0, 50.0, "ppm", Colors.orangeAccent),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLinearSubMetric("Temperature", _temperature, "°C", Icons.thermostat, Colors.deepOrangeAccent),
                _buildLinearSubMetric("Humidity Level", _humidity, "% RH", Icons.water_drop, Colors.tealAccent),
              ],
            )
          ],
        ),
      ),
    );
  }

 Widget _buildRadialGauge(String title, double val, double minVal, double maxVal, String unit, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70)),
        const SizedBox(height: 12),
        SizedBox(
          width: 130,
          height: 130,
          child: CustomPaint(
            // Passing minVal and maxVal cleanly to avoid collisions
            painter: RadialGaugePainter(value: val, min: minVal, max: maxVal, progressColor: color),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Fixed the "Main =>" typo here
                children: [
                  Text(val.toStringAsFixed(1), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(unit, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildLinearSubMetric(String name, double val, String unit, IconData icon, Color themeColor) {
    return Row(
      children: [
        Icon(icon, color: themeColor, size: 28),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(val.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(width: 2),
                Text(unit, style: const TextStyle(fontSize: 11, color: Colors.white54)),
              ],
            )
          ],
        )
      ],
    );
  }

  Widget _buildWeightHistoryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MASS VECTOR ANALYTICS LOG',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_weight.toStringAsFixed(2)} g",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0x1A2196F3), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.scale, color: Colors.blueAccent),
                )
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              width: double.infinity,
              child: _weightHistory.isEmpty
                  ? const Center(
                      child: Text(
                        "Awaiting live stream. Run simulator.py to plot points...", 
                        style: TextStyle(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w400)
                      ),
                    )
                  : CustomPaint(
                      painter: LineChartPainter(
                        history: List.from(_weightHistory),
                        lineColor: Colors.blueAccent,
                        fillColor: Colors.blueAccent.withAlpha(20), 
                      ),
                    ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationPanel() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CONTROL & PIPELINE OVERVIEW',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),
            const Text(
              "System listening to historical telemetry feed via simulator.py script cloud engine pipeline loop.",
              style: TextStyle(fontSize: 13, color: Colors.white60, height: 1.3),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.white24),
                    ),
                    onPressed: () {
                      setState(() {
                        _weightHistory.clear();
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 18, color: Colors.white70),
                    label: const Text("Reset Vector Logs", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 18, color: Colors.white),
                    label: const Text("Export Analytics", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ─── HIGH PERFORMANCE NATIVE CHART CUSTOM PAINTERS ───

class LineChartPainter extends CustomPainter {
  final List<double> history;
  final Color lineColor;
  final Color fillColor;

  LineChartPainter({required this.history, required this.lineColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final gridPaint = Paint()
      ..color = const Color(0xFF334155).withAlpha(51) 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (int i = 1; i < 4; i++) {
      double yGrid = size.height * (i / 4);
      canvas.drawLine(Offset(0, yGrid), Offset(size.width, yGrid), gridPaint);
    }

    double minVal = history[0];
    double maxVal = history[0];
    for (int i = 1; i < history.length; i++) {
      if (history[i] < minVal) minVal = history[i];
      if (history[i] > maxVal) maxVal = history[i];
    }
    
    if (maxVal == minVal) {
      maxVal += 2.0;
      minVal -= 2.0;
    } else {
      double boundsBuffer = (maxVal - minVal) * 0.15;
      maxVal += boundsBuffer;
      minVal -= boundsBuffer;
    }

    final int lenMinusOne = history.length - 1;
    final double divisor = lenMinusOne < 1 ? 1.0 : lenMinusOne.toDouble();
    final double stepX = size.width / divisor;
    
    final linePath = Path();
    final fillPath = Path();

    double calculateCoordinateX(int index) => index * stepX;
    double calculateCoordinateY(double value) {
      double scaleFactor = (value - minVal) / (maxVal - minVal);
      return size.height - (scaleFactor * size.height);
    }

    final startX = calculateCoordinateX(0);
    final startY = calculateCoordinateY(history[0]);

    linePath.moveTo(startX, startY);
    fillPath.moveTo(startX, size.height);
    fillPath.lineTo(startX, startY);

    for (int i = 1; i < history.length; i++) {
      double currentX = calculateCoordinateX(i);
      double currentY = calculateCoordinateY(history[i]);
      linePath.lineTo(currentX, currentY);
      fillPath.lineTo(currentX, currentY);
    }

    fillPath.lineTo(calculateCoordinateX(history.length - 1), size.height);
    fillPath.close();

    canvas.drawPath(fillPath, Paint()..color = fillColor..style = PaintingStyle.fill);

    canvas.drawPath(
      linePath, 
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
    );

    final lastX = calculateCoordinateX(history.length - 1);
    final lastY = calculateCoordinateY(history.last);
    canvas.drawCircle(Offset(lastX, lastY), 7.0, Paint()..color = lineColor.withAlpha(76)); 
    canvas.drawCircle(Offset(lastX, lastY), 4.0, Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.history != history;
  }
}

class RadialGaugePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color progressColor;

  RadialGaugePainter({required this.value, required this.min, required this.max, required this.progressColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    final double halfWidth = size.width / 2;
    final double halfHeight = size.height / 2;
    final double radius = halfWidth < halfHeight ? halfWidth : halfHeight;
    
    const strokeWidth = 10.0;

    final trackPaint = Paint()
      ..color = const Color(0xFF334155).withAlpha(102) 
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      pi * 0.75,
      pi * 1.5,
      false,
      trackPaint,
    );

    final percentage = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final sweepAngle = pi * 1.5 * percentage;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [progressColor.withAlpha(76), progressColor], 
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(pi * 0.75);
    canvas.translate(-center.dx, -center.dy);
    
    if (sweepAngle > 0.001) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        0,
        sweepAngle,
        false,
        progressPaint,
      );
    }
    canvas.restore();

    final angle = pi * 0.75 + sweepAngle;
    final dotX = center.dx + (radius - strokeWidth / 2) * cos(angle);
    final dotY = center.dy + (radius - strokeWidth / 2) * sin(angle);

    canvas.drawCircle(Offset(dotX, dotY), 10.0, Paint()..color = progressColor.withAlpha(51)); 
    canvas.drawCircle(Offset(dotX, dotY), 5.0, Paint()..color = progressColor);
  }

  @override
  bool shouldRepaint(covariant RadialGaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.progressColor != progressColor;
  }
}