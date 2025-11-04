import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// A constant map for available Zikr phrases
const Map<String, String> _adhkar = {
  'سبحان الله': 'سبحان الله',
  'الحمد لله': 'الحمد لله',
  'الله أكبر': 'الله أكبر',
  'لا إله إلا الله': 'لا إله إلا الله',
};

class ZikirByVoicePage extends StatefulWidget {
  const ZikirByVoicePage({super.key});

  @override
  State<ZikirByVoicePage> createState() => _ZikirByVoicePageState();
}

class _ZikirByVoicePageState extends State<ZikirByVoicePage> {
  // --- STT State ---
  late stt.SpeechToText _stt;
  bool _available = false;
  bool _listening = false;
  String _spokenText = ''; // The latest recognized words

  // --- Zikr/Counter State ---
  String _selectedZikr = _adhkar.keys.first; // Currently selected Zikr from the dropdown
  int _zikrCount = 0; // The counter for the selected Zikr

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  // --- STT Initialization and Control Methods (Kept the same) ---

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
      listenFor: const Duration(hours: 1), // 🕐 one full hour
      pauseFor: const Duration(minutes: 5), // long silence tolerance
      onResult: (res) {
        final recognizedWords = res.recognizedWords.trim();
        setState(() {
          _spokenText = recognizedWords;
          // 💡 **New Logic: Check and Count Zikr**
          if (recognizedWords.contains(_selectedZikr)) {
            // Simple check: if the recognized text *contains* the selected zikr.
            // This handles cases where there's slight noise or extra words.
            _zikrCount++;
          }
        });
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

  // --- Zikr/Counter Methods ---

  void _resetCount() {
    setState(() {
      _zikrCount = 0;
    });
  }

  // --- Widget Build (UI) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الذكر بالصوت (مستمر) 🎤')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Zikr Selection and Counter Display
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dropdown for Zikr Selection
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'اختر الذكر',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      value: _selectedZikr,
                      items: _adhkar.keys
                          .map((String zikr) => DropdownMenuItem<String>(
                                value: zikr,
                                child: Text(zikr, textDirection: TextDirection.rtl),
                              ))
                          .toList(),
                      onChanged: _listening // Disable changing while listening
                          ? null
                          : (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedZikr = newValue;
                                  _zikrCount = 0; // Reset count on Zikr change
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 15),

                    // Counter Display
                    Center(
                      child: Text(
                        'العدد: $_zikrCount',
                        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Reset Button
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('تصفير العدد'),
                      onPressed: _resetCount,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            
            // 2. STT Control Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.mic),
                    label: const Text('ابدأ الاستماع'),
                    onPressed: _available && !_listening ? _startListening : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.stop),
                    label: const Text('إيقاف الاستماع'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _listening ? _stopListening : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3. Status
            Text(
              _available
                  ? (_listening
                      ? '🎧 يستمع الآن... قل "${_selectedZikr}"'
                      : '✅ جاهز. الذكر الحالي: $_selectedZikr')
                  : '⚠️ التعرّف على الكلام غير متاح على هذا الجهاز',
              style: const TextStyle(color: Colors.teal, fontSize: 16),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 20),

            // 4. Recognized Text
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _spokenText.isEmpty ? 'ابدأ وتحدث...' : _spokenText,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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