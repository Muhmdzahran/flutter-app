import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ZikirByVoicePage extends StatefulWidget {
  const ZikirByVoicePage({super.key});

  @override
  State<ZikirByVoicePage> createState() => _ZikirByVoicePageState();
}

class _ZikirByVoicePageState extends State<ZikirByVoicePage> {
  late stt.SpeechToText _stt;
  bool _available = false;
  bool _listening = false;
  String _spokenText = '';

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  Future<void> _initStt() async {
    _stt = stt.SpeechToText();
    final ok = await _stt.initialize(
      onError: (e) => debugPrint('Speech error: $e'),
      onStatus: (s) => setState(() => _listening = (s == 'listening')),
    );
    setState(() => _available = ok);
  }

  Future<void> _startListening() async {
    if (!_available) return;

    // Try to select Arabic locale
    const arLocales = ['ar-QA', 'ar-SA', 'ar', 'ar-AE', 'ar-EG', 'ar-LB'];
    String? chosen;
    final locales = await _stt.locales();
    for (final l in locales) {
      if (arLocales.contains(l.localeId)) {
        chosen = l.localeId;
        break;
      }
    }

    setState(() => _spokenText = '');

    await _stt.listen(
      localeId: chosen,
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 5),
      onResult: (res) {
        setState(() => _spokenText = res.recognizedWords.trim());
      },
    );
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    setState(() => _listening = false);
  }

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الذكر بالصوت (تجربة)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.mic),
                    label: const Text('ابدأ'),
                    onPressed: _available && !_listening ? _startListening : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: const Text('إيقاف'),
                    onPressed: _listening ? _stopListening : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _available
                  ? (_listening ? '🎧 يستمع الآن...' : '✅ جاهز للاستماع')
                  : '⚠️ التعرف على الكلام غير متاح',
              style: const TextStyle(color: Colors.teal),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _spokenText.isEmpty ? 'قل شيئًا...' : _spokenText,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
