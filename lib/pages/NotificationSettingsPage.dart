import 'package:flutter/material.dart';
// 💡 Import your Notification Service (Adjust path if necessary)
import '../services/notification_service.dart'; 

// Renamed class to follow convention (NotificationSettingsPage is fine for class)
class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // State to hold the selected time (defaults to 12:00 AM)
  TimeOfDay _selectedTime = const TimeOfDay(hour: 0, minute: 0); 
  
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Logic to load saved time would go here
  }

  // --- Time Picker and Scheduling Logic ---

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context, 
      initialTime: _selectedTime, 
      helpText: 'اختر وقت التذكير اليومي',
      builder: (BuildContext context, Widget? child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      
      // 1. Cancel existing notification before scheduling the new one
      await _notificationService.cancelAllNotifications();

      // 2. Schedule the new daily notification
      await _notificationService.scheduleDailyNotification(
        hour: picked.hour,
        minute: picked.minute,
      );
      
      // 3. 💡 Guard context use after all await calls
      if (!mounted) return; 
      
      // 4. Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تعيين التذكير اليومي بنجاح في: ${_selectedTime.format(context)}',
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
  }

  // --- Widget Build (UI) ---

  @override
  Widget build(BuildContext context) {
    String formattedTime = _selectedTime.format(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات التذكيرات'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Current Time Display Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'وقت التذكير اليومي الحالي:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 2. Select Time Button
            ElevatedButton.icon(
              onPressed: () => _selectTime(context),
              icon: const Icon(Icons.access_time),
              label: const Text(
                'تغيير وقت التذكير',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 15),
            
            // 3. Test Reminder Button
            ElevatedButton.icon(
              onPressed: () {
                _notificationService.showTestNotification();
                // 💡 No await needed, so we check mounted before showing snackbar
                if (!mounted) return; 
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'جاري إرسال تذكير فوري (اختبار)...',
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.send_time_extension),
              label: const Text(
                'اختبار التذكير الآن',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                backgroundColor: Theme.of(context).colorScheme.secondary, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 4. Cancel All Button
            OutlinedButton.icon(
              onPressed: () async { // Ensure onPressed is async
                await _notificationService.cancelAllNotifications();
                
                // Set state only after the await
                setState(() {
                  _selectedTime = const TimeOfDay(hour: 0, minute: 0); 
                });

                // 💡 Guard context use after the await call
                if (!mounted) return; 

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'تم إلغاء جميع التذكيرات بنجاح.',
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_off),
              label: const Text('إلغاء التذكير اليومي'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
            
            const Spacer(),
            
            // Note
            const Text(
              'ملاحظة: التذكير يتكرر تلقائياً كل يوم في الوقت الذي تختاره.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}