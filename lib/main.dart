import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'dart:math';

// ─── Entry point للـ Overlay ───────────────────────────────
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OverlayApp());
}

// ─── Entry point الرئيسي ────────────────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TasbihApp());
}

// ══════════════════════════════════════════════════════════════
//  الألوان الثابتة
// ══════════════════════════════════════════════════════════════
const kGold      = Color(0xFFD4AF37);
const kGoldLight = Color(0xFFF5E07A);
const kGoldDark  = Color(0xFF9A7D0A);
const kBg        = Color(0xFF080808);

// ══════════════════════════════════════════════════════════════
//  تطبيق الـ Overlay العائم
// ══════════════════════════════════════════════════════════════
class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: OverlayWidget(),
      );
}

class OverlayWidget extends StatefulWidget {
  const OverlayWidget({super.key});
  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget>
    with SingleTickerProviderStateMixin {
  int count = 0;
  int total = 0;
  int round = 1;
  static const target = 100;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween(begin: 1.0, end: 0.88).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _loadState();
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data != null) _handleData(data);
    });
  }

  void _handleData(dynamic data) {
    if (data is Map) {
      setState(() {
        count = data['count'] ?? count;
        total = data['total'] ?? total;
        round = data['round'] ?? round;
      });
    }
  }

  Future<void> _loadState() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      count = p.getInt('count') ?? 0;
      total = p.getInt('total') ?? 0;
      round = p.getInt('round') ?? 1;
    });
  }

  Future<void> _saveState() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('count', count);
    await p.setInt('total', total);
    await p.setInt('round', round);
  }

  Future<void> _tap() async {
    _ctrl.forward().then((_) => _ctrl.reverse());
    setState(() {
      count++;
      total++;
      if (count >= target) {
        count = 0;
        round++;
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    });
    await _saveState();
    FlutterOverlayWindow.shareData({
      'count': count, 'total': total, 'round': round
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = count / target;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _tap,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFF2a2200), Color(0xFF0a0a00)],
                center: Alignment(-0.3, -0.3),
              ),
              border: Border.all(color: kGold.withOpacity(0.4), width: 2),
              boxShadow: [
                BoxShadow(color: kGold.withOpacity(0.25), blurRadius: 16, spreadRadius: 2),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // شريط الدائرة
                SizedBox(
                  width: 106, height: 106,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: kGold.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(kGold),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [kGoldLight, kGold, kGoldDark],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(b),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 34, fontWeight: FontWeight.bold,
                          color: Colors.white, height: 1,
                        ),
                      ),
                    ),
                    Text(
                      'ج$round',
                      style: TextStyle(
                        fontSize: 10, color: kGold.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════
//  التطبيق الرئيسي
// ══════════════════════════════════════════════════════════════
class TasbihApp extends StatelessWidget {
  const TasbihApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'مسبحة',
        theme: ThemeData(
          scaffoldBackgroundColor: kBg,
          colorScheme: const ColorScheme.dark(primary: kGold),
          fontFamily: 'Amiri',
        ),
        home: const TasbihHome(),
      );
}

class TasbihHome extends StatefulWidget {
  const TasbihHome({super.key});
  @override
  State<TasbihHome> createState() => _TasbihHomeState();
}

class _TasbihHomeState extends State<TasbihHome>
    with SingleTickerProviderStateMixin {
  int count = 0, total = 0, round = 1;
  static const target = 100;
  bool soundOn = true, vibOn = true;
  bool _overlayActive = false;

  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 130));
    _scale = Tween(begin: 1.0, end: 0.91).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _loadState();
    _checkOverlayPermission();
    // استقبال بيانات من الـ Overlay
    FlutterOverlayWindow.overlayListener.listen((data) {
      if (data is Map) {
        setState(() {
          count = data['count'] ?? count;
          total = data['total'] ?? total;
          round = data['round'] ?? round;
        });
      }
    });
  }

  Future<void> _checkOverlayPermission() async {
    final granted = await FlutterOverlayWindow.isPermissionGranted();
    if (!granted && mounted) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1a1500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('إذن مطلوب', style: TextStyle(color: kGold, fontFamily: 'Amiri')),
        content: const Text(
          'لإظهار المسبحة فوق التطبيقات، يجب منح إذن "العرض فوق التطبيقات"',
          style: TextStyle(color: Colors.white70, fontFamily: 'Amiri'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لاحقاً', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kGold),
            onPressed: () async {
              Navigator.pop(context);
              await FlutterOverlayWindow.requestPermission();
            },
            child: const Text('منح الإذن', style: TextStyle(color: kBg)),
          ),
        ],
      ),
    );
  }

  Future<void> _loadState() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      count = p.getInt('count') ?? 0;
      total = p.getInt('total') ?? 0;
      round = p.getInt('round') ?? 1;
      soundOn = p.getBool('soundOn') ?? true;
      vibOn = p.getBool('vibOn') ?? true;
    });
  }

  Future<void> _saveState() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('count', count);
    await p.setInt('total', total);
    await p.setInt('round', round);
    await p.setBool('soundOn', soundOn);
    await p.setBool('vibOn', vibOn);
  }

  Future<void> _tap() async {
    _ctrl.forward().then((_) => _ctrl.reverse());
    final milestoneReached = count > 0 && (count + 1) % 10 == 0 && count + 1 < target;
    final completed = count + 1 >= target;

    setState(() {
      count++;
      total++;
      if (count >= target) {
        count = 0;
        round++;
        _showMilestoneSnack('✦', 'جزاك الله خيراً! الجولة $round');
      } else if (milestoneReached) {
        _showMilestoneSnack('◈', '${count} صلاة');
      }
    });

    if (vibOn) {
      final canVib = await Vibration.hasVibrator() ?? false;
      if (canVib) {
        if (completed) {
          Vibration.vibrate(pattern: [0, 60, 40, 60]);
        } else {
          Vibration.vibrate(duration: 25);
        }
      }
    }

    await _saveState();
    if (_overlayActive) {
      FlutterOverlayWindow.shareData({
        'count': count, 'total': total, 'round': round
      });
    }
  }

  void _undo() {
    if (count > 0) {
      setState(() { count--; total = max(0, total - 1); });
      _saveState();
    }
  }

  void _reset() {
    setState(() { count = 0; round = 1; total = 0; });
    _saveState();
    _showMilestoneSnack('↺', 'تمت الإعادة');
  }

  void _showMilestoneSnack(String icon, String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$icon  ', style: const TextStyle(fontSize: 18)),
            Text(msg, style: const TextStyle(
              fontFamily: 'Amiri', fontSize: 16, color: kGold)),
          ],
        ),
        backgroundColor: const Color(0xFF1a1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: kGold, width: 0.5),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleOverlay() async {
    final granted = await FlutterOverlayWindow.isPermissionGranted();
    if (!granted) {
      await FlutterOverlayWindow.requestPermission();
      return;
    }
    if (_overlayActive) {
      await FlutterOverlayWindow.closeOverlay();
      setState(() => _overlayActive = false);
    } else {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: 'مسبحة',
        overlayContent: 'الصلاة على النبي ﷺ',
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        width: 110,
        height: 110,
      );
      setState(() => _overlayActive = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = count / target;
    final screenW = MediaQuery.of(context).size.width;
    final btnSize = min(screenW * 0.72, 290.0);

    return Scaffold(
      backgroundColor: kBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.2,
            colors: [Color(0x12D4AF37), kBg],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── شريط علوي ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // زر الـ Overlay
                    GestureDetector(
                      onTap: _toggleOverlay,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _overlayActive ? kGold : kGold.withOpacity(0.3),
                          ),
                          color: _overlayActive
                              ? kGold.withOpacity(0.15)
                              : Colors.transparent,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _overlayActive ? Icons.picture_in_picture : Icons.picture_in_picture_outlined,
                              color: _overlayActive ? kGold : kGold.withOpacity(0.5),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _overlayActive ? 'إخفاء العائم' : 'عائم فوق الكل',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 13,
                                color: _overlayActive ? kGold : kGold.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      'مسبحة',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 20,
                        color: kGold.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ── النص العلوي ──
              Text(
                'اللهم صلِّ وسلِّم\nعلى نبينا محمد ﷺ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  color: kGold.withOpacity(0.75),
                  height: 1.8,
                ),
              ),

              const Spacer(),

              // ── الزر الرئيسي ──
              GestureDetector(
                onTap: _tap,
                child: ScaleTransition(
                  scale: _scale,
                  child: SizedBox(
                    width: btnSize,
                    height: btnSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // الشكل السداسي
                        CustomPaint(
                          size: Size(btnSize, btnSize),
                          painter: HexPainter(progress: progress),
                        ),
                        // الرقم
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [kGoldLight, kGold, kGoldDark],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ).createShader(b),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: btnSize * 0.28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            ),
                            Text(
                              'اضغط هنا',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 13,
                                color: kGold.withOpacity(0.35),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ── الإحصائيات ──
              Container(
                width: MediaQuery.of(context).size.width * 0.88,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kGold.withOpacity(0.1)),
                  color: kGold.withOpacity(0.03),
                ),
                child: Row(
                  children: [
                    _stat('$round', 'الجولة'),
                    _divider(),
                    _stat('$total', 'الإجمالي'),
                    _divider(),
                    _stat('${max(0, target - count)}', 'المتبقي'),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── أزرار التحكم ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _actionBtn('↩ تراجع', _undo, false),
                    const SizedBox(width: 10),
                    _actionBtn('↺ إعادة', _reset, true),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _toggleBtn(
                      soundOn ? '🎵 نغمة' : '🔇 نغمة',
                      soundOn,
                      () => setState(() { soundOn = !soundOn; _saveState(); }),
                    ),
                    const SizedBox(width: 10),
                    _toggleBtn(
                      vibOn ? '📳 اهتزاز' : '📴 اهتزاز',
                      vibOn,
                      () => setState(() { vibOn = !vibOn; _saveState(); }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String val, String label) => Expanded(
        child: Column(
          children: [
            Text(val, style: const TextStyle(
              fontFamily: 'Amiri', fontSize: 20, color: kGold)),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              fontSize: 9, color: kGold.withOpacity(0.3),
              letterSpacing: 1.5)),
          ],
        ),
      );

  Widget _divider() => Container(
        width: 1, height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, kGold.withOpacity(0.2), Colors.transparent],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
      );

  Widget _actionBtn(String txt, VoidCallback fn, bool isRed) => Expanded(
        child: GestureDetector(
          onTap: fn,
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRed ? Colors.red.withOpacity(0.25) : kGold.withOpacity(0.2),
              ),
              color: Colors.transparent,
            ),
            child: Text(
              txt,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 15,
                color: isRed ? Colors.red.withOpacity(0.5) : kGold.withOpacity(0.6),
              ),
            ),
          ),
        ),
      );

  Widget _toggleBtn(String txt, bool on, VoidCallback fn) => Expanded(
        child: GestureDetector(
          onTap: fn,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: on ? kGold.withOpacity(0.45) : kGold.withOpacity(0.1),
              ),
              color: on ? kGold.withOpacity(0.09) : Colors.transparent,
            ),
            child: Text(
              txt,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 15,
                color: on ? kGold : kGold.withOpacity(0.25),
                decoration: on ? null : TextDecoration.lineThrough,
                decorationColor: kGold.withOpacity(0.25),
              ),
            ),
          ),
        ),
      );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════
//  رسم الشكل السداسي
// ══════════════════════════════════════════════════════════════
class HexPainter extends CustomPainter {
  final double progress;
  HexPainter({required this.progress});

  List<Offset> _hexPoints(double cx, double cy, double r) {
    return List.generate(6, (i) {
      final angle = (pi / 3) * i - pi / 2;
      return Offset(cx + r * cos(angle), cy + r * sin(angle));
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final r = min(cx, cy) - 4;
    final pts = _hexPoints(cx, cy, r);
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var p in pts.skip(1)) path.lineTo(p.dx, p.dy);
    path.close();

    // خلفية
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [const Color(0xFF2a2200), const Color(0xFF0e0e00)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    // حدود خافتة
    canvas.drawPath(
      path,
      Paint()
        ..color = kGold.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // شريط التقدم (مبني على PathMetric)
    final measure = path.computeMetrics().first;
    final progressPath = measure.extractPath(0, measure.length * progress);
    canvas.drawPath(
      progressPath,
      Paint()
        ..shader = const LinearGradient(
          colors: [kGoldDark, kGoldLight, kGold],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // ظل داخلي ذهبي
    canvas.drawPath(
      path,
      Paint()
        ..color = kGold.withOpacity(0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.inner, 12)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(HexPainter old) => old.progress != progress;
}
