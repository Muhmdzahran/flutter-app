import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// Initial constant map for available Zikr phrases
const Map<String, String> _initialAdhkar = {
  'سبحان الله': 'سبحان الله',
  'الحمد لله': 'الحمد لله',
  'الله اكبر': 'الله اكبر',
  'استغفر الله': 'استغفر الله',
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
  String _spokenText = '';

  // --- Zikr/Counter State ---
  // 💡 [CHANGE] Make this list mutable by moving it into the State
  Map<String, String> _adhkar = Map.from(_initialAdhkar);
  String _selectedZikr = _initialAdhkar.keys.first;
  int _zikrCount = 0;
  int _processedTextLength = 0;
  int _textOccurrenceCount = 0;

  final _customZikrController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  // --- STT Initialization and Control Methods (Logic Unchanged) ---

  Future<void> _initStt() async {
    _stt = stt.SpeechToText();
    final ok = await _stt.initialize(
      onError: (e) => debugPrint('Speech error: $e'),
      onStatus: (s) {
        debugPrint('STT status: $s');
        if (s == 'notListening' && _listening) {
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
      _processedTextLength = 0;
      _textOccurrenceCount = 0;
    });

    await _stt.listen(
      localeId: chosen,
      listenFor: const Duration(hours: 1),
      pauseFor: const Duration(minutes: 15),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: false,
      ),
      onResult: (res) {
        final recognizedWords = res.recognizedWords.trim();
        final newSegment = recognizedWords.substring(_processedTextLength);
        final newZikrCount = _countOccurrences(newSegment, _selectedZikr);

        setState(() {
          _spokenText = recognizedWords;

          if (newZikrCount > 0) {
            _zikrCount += newZikrCount;
            _processedTextLength = recognizedWords.length;
          }
          _textOccurrenceCount = _zikrCount;
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
    _customZikrController.dispose();
    super.dispose();
  }

  // --- Zikr/Counter Methods (Logic Unchanged) ---

  int _countOccurrences(String text, String target) {
    if (target.isEmpty) return 0;

    String normalize(String s) {
      return s.replaceAll(RegExp(r'[أ]'), 'ا');
    }

    final normalizedText = normalize(text);
    final normalizedTarget = normalize(target);

    int count = 0;
    int index = 0;

    while (true) {
      index = normalizedText.indexOf(normalizedTarget, index);
      if (index == -1) break;
      count++;
      index += normalizedTarget.length;
    }
    return count;
  }

  void _resetCount() {
    setState(() {
      _zikrCount = 0;
      _processedTextLength = 0;
      _textOccurrenceCount = 0;
      _spokenText = '';
    });
  }

  // 💡 [NEW METHOD] for adding custom Zikr
  void _addCustomZikr(String zikr) {
    final trimmedZikr = zikr.trim();
    if (trimmedZikr.isNotEmpty && !_adhkar.containsKey(trimmedZikr)) {
      setState(() {
        _adhkar[trimmedZikr] = trimmedZikr;
        _selectedZikr = trimmedZikr;
        _resetCount();
      });
    }
  }

  // 💡 [NEW WIDGET] to show the Add Custom Zikr Dialog
  void _showAddCustomZikrDialog(BuildContext context) {
    _customZikrController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة ذكر مخصص'),
            content: TextField(
              controller: _customZikrController,
              decoration: const InputDecoration(
                labelText: 'الذكر الذي تريد إضافته (مثلاً: لا حول ولا قوة إلا بالله)',
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('إلغاء'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: const Text('إضافة'),
                onPressed: () {
                  if (_customZikrController.text.isNotEmpty) {
                    _addCustomZikr(_customZikrController.text);
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Widget Build (UI Improvements) ---

  Widget _buildCounterDisplay(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'عدد التسبيحات',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white.withOpacity(0.8),
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 10),
          Text(
            '$_zikrCount',
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('المسبحة الصوتية 🎤'),
        centerTitle: true,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Main Counter Display
              _buildCounterDisplay(context),

              const SizedBox(height: 20),

              // 2. Zikr Selection and Controls
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      // Dropdown for Zikr Selection
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'اختر الذكر',
                          border: const OutlineInputBorder(),
                          enabled: !_listening,
                          labelStyle: TextStyle(color: _listening ? Colors.grey : theme.primaryColor),
                        ),
                        value: _selectedZikr, // Use 'value' instead of 'initialValue' when managed by state
                        items: _adhkar.keys
                            .map((String zikr) => DropdownMenuItem<String>(
                                  value: zikr,
                                  child: Text(zikr, style: const TextStyle(fontSize: 18)),
                                ))
                            .toList(),
                        onChanged: _listening
                            ? null
                            : (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedZikr = newValue;
                                    _resetCount();
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 15),

                      // Row for Add Custom Zikr and Reset Button
                      Row(
                        children: [
                          // 💡 [NEW BUTTON] Add Custom Zikr
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('إضافة ذكر'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.teal,
                                side: const BorderSide(color: Colors.teal),
                              ),
                              onPressed: _listening ? null : () => _showAddCustomZikrDialog(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Reset Button
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.refresh),
                              label: const Text('تصفير'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              onPressed: _resetCount,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 3. Status and Control Buttons
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: _listening ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: _listening ? Colors.green.shade200 : Colors.blue.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _available
                          ? (_listening
                              ? '🎧 يستمع الآن... قل: **$_selectedZikr**'
                              : '✅ جاهز. الذكر الحالي: **$_selectedZikr**')
                          : '⚠️ التعرّف على الكلام غير متاح على هذا الجهاز',
                      style: TextStyle(
                        color: _listening ? Colors.green.shade700 : Colors.blue.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.mic, color: Colors.white),
                            label: const Text('ابدأ الاستماع', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 5,
                            ),
                            onPressed: _available && !_listening ? _startListening : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.stop, color: Colors.white),
                            label: const Text('إيقاف', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 5,
                            ),
                            onPressed: _listening ? _stopListening : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. Recognized Text Display
              Text(
                'النص المُتعرّف عليه:',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              Container(
                height: 150,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _spokenText.isEmpty ? 'ابدأ وتحدث... سيظهر الذكر الذي تقوله هنا.' : _spokenText,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              if (_listening)
                Text(
                  'إجمالي مرات ظهور الذكر في النص الحالي: **$_textOccurrenceCount**',
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}