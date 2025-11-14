import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// 💡 [UPDATE] The new, comprehensive list of Zikr phrases
const Map<String, String> _initialAdhkar = {
  'لا حول ولا قوة الا بالله': 'لا حول ولا قوة الا بالله',
  'سبحان الله وبحمده': 'سبحان الله وبحمده',
  'استغفر الله': 'استغفر الله',
  'اللهم صل وسلم على نبينا محمد': 'اللهم صل وسلم على نبينا محمد',
  'الحمد لله': 'الحمد لله',
  'سبحان الله وبحمده سبحان الله العظيم': 'سبحان الله وبحمده سبحان الله العظيم',
  'سبحان الله': 'سبحان الله',
  'سبحان الله العظيم': 'سبحان الله العظيم',
  'لا اله الا الله': 'لا اله الا الله',
  'الله اكبر': 'الله اكبر',
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
  final Map<String, String> _adhkar = Map.from(_initialAdhkar);
  late String _selectedZikr;
  int _zikrCount = 0;
  int _processedTextLength = 0;
  int _textOccurrenceCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedZikr = _initialAdhkar.keys.first;
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
    super.dispose();
  }

  // --- Zikr/Counter Methods ---

  // 💡 [REVISED] Helper function with enhanced normalization for common STT errors (صل/صلي, Hamza)
  int _countOccurrences(String text, String target) {
    if (target.isEmpty) return 0;

    // 1. Core Normalization Function (Hamza/Alif Maqsura)
    String normalize(String s) {
      // Consolidate Hamza variations (أ, آ, إ, ئ, ؤ) to a simple Alif (ا)
      s = s.replaceAll(RegExp(r'[أآإئؤ]'), 'ا');
      // Normalize Alif Maqsura (ى) to Ya' (ي)
      s = s.replaceAll('ى', 'ي');
      return s;
    }

    // 2. Define the set of normalized target strings to check against
    List<String> normalizedTargets = [];
    String baseTarget = normalize(target);
    normalizedTargets.add(baseTarget);

    // Add common STT error variations (e.g., صل <-> صلي)
    if (baseTarget.endsWith('ل') && baseTarget.length > 1) {
      // If target is 'صل', add 'صلي'
      normalizedTargets.add(baseTarget + 'ي');
    } else if (baseTarget.endsWith('ي') && baseTarget.length > 1) {
      // If target is 'صلي', add 'صل'
      normalizedTargets.add(baseTarget.substring(0, baseTarget.length - 1));
    }
    
    // Add variations for 'الا' / 'إلا'
    if (baseTarget.contains('ا للّه')) {
        normalizedTargets.add(baseTarget.replaceAll('ا للّه', 'ا للّه'));
    }

    // 3. Normalize the recognized text once
    final normalizedText = normalize(text);

    int totalCount = 0;
    
    // 4. Iterate over all valid targets and count occurrences
    for (final normalizedTarget in normalizedTargets) {
      if (normalizedTarget.isEmpty) continue;

      int count = 0;
      int index = 0;

      while (true) {
        index = normalizedText.indexOf(normalizedTarget, index);
        if (index == -1) break;
        count++;
        index += normalizedTarget.length;
      }
      
      // If we found a match for any variation, use that count and stop.
      if (count > 0) {
          totalCount = count;
          break;
      }
    }
    
    return totalCount;
  }

  void _resetCount() {
    setState(() {
      _zikrCount = 0;
      _processedTextLength = 0;
      _textOccurrenceCount = 0;
      _spokenText = '';
    });
  }

  void _selectZikr(String zikr) {
    if (_listening) return; // Cannot change while listening
    setState(() {
      _selectedZikr = zikr;
      _resetCount();
    });
  }

  // --- Widget Builders (UI) ---

  Widget _buildCounterDisplay(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary, // Use theme color
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

  Widget _buildZikrCatalog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'اختر الذكر من القائمة:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80, // Fixed height for the horizontal list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true, // RTL scrolling
            itemCount: _adhkar.length,
            itemBuilder: (context, index) {
              final zikr = _adhkar.keys.elementAt(index);
              final isSelected = zikr == _selectedZikr;
              final theme = Theme.of(context);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: GestureDetector(
                  onTap: _listening ? null : () => _selectZikr(zikr),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : theme.cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      zikr,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (theme.brightness == Brightness.dark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Zikr Catalog (Horizontal Row)
              _buildZikrCatalog(),

              const SizedBox(height: 20),
              
              // 2. Main Counter Display
              _buildCounterDisplay(context),

              const SizedBox(height: 20),

              // 3. Control Buttons and Reset
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const SizedBox(width: 12),
                  // Reset Button
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: IconButton.filled(
                      icon: const Icon(Icons.refresh),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.tertiary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _resetCount,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // 4. Status and Selected Zikr
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _listening ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Text(
                      _available
                          ? (_listening
                              ? '🎧 يستمع الآن... قل: **$_selectedZikr**'
                              : '✅ جاهز. الذكر المحدد: **$_selectedZikr**')
                          : '⚠️ التعرّف على الكلام غير متاح على هذا الجهاز',
                      style: TextStyle(
                        color: _listening ? Colors.green.shade700 : Colors.blue.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_listening)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'إجمالي العد حتى الآن: **$_textOccurrenceCount**',
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 5. Recognized Text Display
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
            ],
          ),
        ),
      ),
    );
  }
}