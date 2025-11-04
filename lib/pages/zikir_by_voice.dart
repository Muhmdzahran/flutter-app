import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:vibration/vibration.dart';

class ZikirByVoicePage extends StatefulWidget {
  const ZikirByVoicePage({super.key});

  @override
  State<ZikirByVoicePage> createState() => _ZikirByVoicePageState();
}

class _ZikirByVoicePageState extends State<ZikirByVoicePage> {
  late stt.SpeechToText _stt;
  bool _available = false;
  bool _listening = false;

  String _selected = 'سبحان الله';
  String _lastHeard = '';
  int _count = 0;

  static const List<String> _phrases = [
    'سبحان الله',
    'الحمد لله',
    'لا إله إلا الله',
    'الله أكبر',
    'أستغفر الله',
  ];

  Future<void> _initStt() async {
    _stt = stt.SpeechToText();
    final avail = await _stt.initialize(
      onError: (e) => debugPrint('SpeechToText error: $e'),
      onStatus: (status) {
        debugPrint('Status: $status');
      },
    );
    setState(() => _available = avail);
  }

  Future<void> _startListening() async {
    if (!_available) return;

    setState(() {
      _count = 0;
      _lastHeard = '';
      _listening = true;
    });

    const arabicLocales = ['ar-QA', 'ar-SA', 'ar', 'ar-AE', 'ar-EG', 'ar-LB'];
    String? chosen;
    final locales = await _stt.locales();
    for (final l in locales) {
      if (arabicLocales.contains(l.localeId)) {
        chosen = l.localeId;
        break;
      }
    }

    await _stt.listen(
      localeId: chosen,
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
      listenFor: const Duration(hours: 1), // 🕐 1-hour continuous session
      pauseFor: const Duration(seconds: 30), // Long silence tolerance
      onResult: (res) async {
        final txt = res.recognizedWords.trim();
        if (txt.isEmpty) return;
        setState(() => _lastHeard = txt);

        // Count if the selected phrase appears in the transcript
        if (txt.contains(_selected)) {
          setState(() => _count++);
          if (await Vibration.hasVibrator() ?? false) {
            Vibration.vibrate(duration: 40);
          }
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    setState(() => _listening = false);
  }

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canListen = _available && !_listening;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الذكر بالصوت'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('اختر الذكر:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selected,
                    items: _phrases
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selected = v ?? _selected;
                      _count = 0;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('العدد الحالي', style: TextStyle(fontSize: 18)),
                    Text('$_count',
                        style: const TextStyle(
                            fontSize: 40, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('آخر مسموع: $_lastHeard',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.mic),
                    onPressed: canListen ? _startListening : null,
                    label: const Text('ابدأ الاستماع'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.stop),
                    onPressed: _listening ? _stopListening : null,
                    label: const Text('إيقاف'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _available
                  ? (_listening ? '🎧 يستمع الآن بشكل مستمر...' : '✅ جاهز للاستماع')
                  : '⚠️ التعرّف على الكلام غير متاح على هذا الجهاز',
              style: const TextStyle(color: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }
}
