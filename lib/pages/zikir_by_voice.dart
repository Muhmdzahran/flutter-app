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
      onStatus: (s) {
        debugPrint('STT status: $s');
        if (s == 'notListening' && _listening) {
          // 🔁 Restart automatically when speech pauses
          _restartListening();
        }
      },
    );
    setState(() => _available = ok);
  }

  Future<void> _restartListening() async {
    if (!_listening) return;
    debugPrint('Restarting listening...');
    await _stt.stop();
    await Future.delayed(const Duration(milliseconds: 300));
    await _startListening();
  }

  Future<void> _startListening() async {
    if (!_available) return;

    // Arabic locales preferred
    const arLocales = ['ar-QA', 'ar-SA', 'ar', 'ar-AE', 'ar-EG', 'ar-LB'];
    String? chosen;
    final locales = await _stt.locales();
    for (final l in locales) {
      if (arLocales.contains(l.localeId)) {
        chosen = l.localeId;
        break;
      }
    }

    setState(() {
      _spokenText = '';
      _listening = true;
    });

    await _stt.listen(
      localeId: chosen,
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      onResult: (res) {
        setState(() => _spokenText = res.recognizedWords.trim());
      },
    );
  }

  Future<void> _stopListening() async {
    setState(() => _listening = false);
    await _stt.stop();
  }

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الذكر بالصوت (مستمر)')),
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
                  ? (_listening ? '🎧 يستمع الآن بشكل مستمر...' : '✅ جاهز للاستماع')
                  : '⚠️ التعرّف على الكلام غير متاح على هذا الجهاز',
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
                    _spokenText.isEmpty ? 'ابدأ وتحدث...' : _spokenText,
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
