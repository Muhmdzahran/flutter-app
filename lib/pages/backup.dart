import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// A constant map for available Zikr phrases
const Map<String, String> _adhkar = {
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
 String _spokenText = ''; // The latest full recognized text

 // --- Zikr/Counter State ---
 String _selectedZikr = _adhkar.keys.first; // Currently selected Zikr from the dropdown
 int _zikrCount = 0; // The primary counter
 // 💡 [إضافة] متغير لتتبع طول النص الذي تم مسحه ضوئيًا وعده
 int _processedTextLength = 0; 
 int _textOccurrenceCount = 0; // How many times the Zikr appears in the full recognized text ("Ctrl+F" count)

 @override
 void initState() {
  super.initState();
  _initStt();
 }

 // --- STT Initialization and Control Methods ---

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

 // Arabic locales preferred (adjust if needed for your specific region)
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
  // 💡 [تحديث] إعادة تعيين طول النص المعالج عند بدء الاستماع
  _processedTextLength = 0; 
  _textOccurrenceCount = 0; 
 });

 await _stt.listen(
  localeId: chosen,
  listenFor: const Duration(hours: 1), // Long listening duration
  pauseFor: const Duration(minutes: 15), // Long silence tolerance
  // 💡 [FIX] Replaced deprecated parameters with SpeechListenOptions
  listenOptions: stt.SpeechListenOptions(
   listenMode: stt.ListenMode.dictation,
   partialResults: true,
   cancelOnError: false,
  ),
  onResult: (res) {
   final recognizedWords = res.recognizedWords.trim();
   
   // ** المنطق الجديد: مسح النص الجديد فقط **
   // استخراج الجزء الذي لم تتم معالجته بعد
   final newSegment = recognizedWords.substring(_processedTextLength);

   // حساب عدد مرات ظهور الذكر في الجزء الجديد فقط
   final newZikrCount = _countOccurrences(newSegment, _selectedZikr);
   
   setState(() {
    _spokenText = recognizedWords;

    if (newZikrCount > 0) {
     // زيادة العداد الكلي بعدد مرات الظهور الجديدة
     _zikrCount += newZikrCount;
     
     // تحديث طول النص المعالج لمنع العد المزدوج في المرة القادمة
     _processedTextLength = recognizedWords.length;
    }
    
    // تحديث عداد الظهور (للعرض فقط)
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

// Helper function to count non-overlapping occurrences of a substring
int _countOccurrences(String text, String target) {
 if (target.isEmpty) return 0;
 
 // 💡 NORMALIZATION FUNCTION
 String normalize(String s) {
  return s
    // 1. Consolidates 'أ' to a simple Alif (ا)
    .replaceAll(RegExp(r'[أ]'), 'ا'); 
 }

 // Apply normalization to both strings before comparison
 final normalizedText = normalize(text);
 final normalizedTarget = normalize(target);
 
 int count = 0;
 int index = 0;
 
 // Search using the normalized strings
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
   // 💡 [تحديث] إعادة تعيين طول النص المعالج عند التصفير
   _processedTextLength = 0; 
   _textOccurrenceCount = 0;
   _spokenText = '';
  });
 }

 // --- Widget Build (UI) ---

 @override
 Widget build(BuildContext context) {
  return Scaffold(
   appBar: AppBar(title: const Text('الذكر بالصوت والمُسبحة الرقمية 🎤')),
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
           // 💡 [FIX] Replaced deprecated 'value' with 'initialValue'
           initialValue: _selectedZikr,
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
                 _resetCount(); // Use the reset function
                });
               }
              },
          ),
          const SizedBox(height: 15),

          // Counter Display (Primary)
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

      const SizedBox(height: 10),

      // 3. Status and "Ctrl+F" Count
      Text(
       _available
         ? (_listening
           ? '🎧 يستمع الآن... قل "$_selectedZikr"'
           : '✅ جاهز. الذكر الحالي: $_selectedZikr')
         : '⚠️ التعرّف على الكلام غير متاح على هذا الجهاز',
       style: const TextStyle(color: Colors.teal, fontSize: 16),
       textAlign: TextAlign.center,
       textDirection: TextDirection.rtl,
      ),
      
      // Occurrence Counter Display ("Ctrl+F" style)
      if (_listening) 
       Text(
        'معدل الظهور في النص الحالي: **$_textOccurrenceCount** مرة',
        style: const TextStyle(color: Colors.purple, fontSize: 14, fontWeight: FontWeight.bold),
        textDirection: TextDirection.rtl,
       ),

      const SizedBox(height: 10),

      // 4. Recognized Text Display
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