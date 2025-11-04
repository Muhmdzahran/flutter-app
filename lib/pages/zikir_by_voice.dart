import 'dart:async';
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

  // Selected phrase to count
  String _selected = 'سبحان الله';

  // Running transcript & counts
  String _lastHeard = '';
  int _count = 0;

  // Supported phrases
  static const List<String> _phrases = [
    'سبحان الله',
    'الحمد لله',
    'لا إله إلا الله',
    'الله أكبر',
    'أستغفر الله',
  ];

  // Simple normalizer: remove tatweel & common diacritics
  String _normalize(String s) {
    const diacritics = [
      '\u064B', // tanween fath
      '\u064C', // tanween damm
      '\u064D', // tanween kasr
      '\u064E', // fatha
      '\u064F', // damma
      '\u0650', // kasra
      '\u0651', // shadda
      '\u0652', // sukun
      '\u0640', // tatweel
    ];
    var out = s;
    for (final d in diacritics) {
      out = out.replaceAll(d, '');
    }
    return out.trim();
  }

  int _countOccurrences(String haystack, String needle) {
    // Count whole-phrase occurrences (normalized)
    final h = _normalize(haystack);
    final n = _normalize(needle);
    if (h.isEmpty || n.isEmpty) return 0;

    // Split to tokens by whitespace and re-join with sentinel to avoid overlaps
    // For Arabic phrases it’s usually exact phrase match:
    int count = 0;
    int index = 0;
    while (true) {
      final found = h.indexOf(n, index);
      if (found == -1) break;
      count++;
      index = found + n.length;
    }
    return count;
  }

  Future<void> _initStt() async {
    _stt = stt.SpeechToText();
    final avail = await _stt.initialize(
      onStatus: (s) => setState(() => _listening = s == 'listening'),
      onError: (e) => debugPrint('STT error: $e'),
    );
    setState(() => _available = avail);
  }

  Future<void> _startListening() async {
    if (!_available) return;
    // Arabic locale; fallback to device default if unavailable
    const arabicLocales = ['ar-QA', 'ar-SA', 'ar', 'ar-AE', 'ar-EG', 'ar-LB'];
    String? chosen;
    final locales = await _stt.locales();
    for (final l in locales) {
      if (arabicLocales.contains(l.localeId)) {
        chosen = l.localeId;
        break;
      }
    }

    _lastHeard = '';
    _count = 0;
    setState(() {});

    await _stt.listen(
      localeId: chosen,            // null -> device default
      listenMode: stt.ListenMode.dictation,
      onResult: (res) async {
        final txt = res.recognizedWords;
        if (txt.isEmpty) return;
        setState(() => _lastHeard = txt);

        final added = _countOccurrences(txt, _selected);
        if (added > 0) {
          setState(() => _count += added);
          if (await Vibration.hasVibrator() ?? false) {
            Vibration.vibrate(duration: 60);
          }
        }
      },
      partialResults: true,
      cancelOnError: false,
      listenFor: const Duration(minutes: 2), // long session; restart as needed
      pauseFor: const Duration(seconds: 4),
      onSoundLevelChange: null,
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
        title: const Text('الذكر بالصوت (Offline-capable on Android/iOS)'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Phrase picker
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
                      _count = 0; // reset when changing
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Counter
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('العدد', style: TextStyle(fontSize: 18)),
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

            // Controls
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
                  ? (_listening ? 'يستمع الآن...' : 'جاهز للاستماع')
                  : 'التعرّف على الكلام غير متاح على هذا الجهاز',
              style: const TextStyle(color: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }
}
