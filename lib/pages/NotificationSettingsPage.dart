import 'package:flutter/material.dart';
// 💡 Import your Notification Service
import '../services/notification_service.dart'; 
// You may need to adjust the path above based on your exact structure

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // State to hold the selected time (defaults to 12:00 AM)
  TimeOfDay _selectedTime = const TimeOfDay(hour: 0, minute: 0); 
  
  // Instance of the service
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // 💡 Ideally, you would load the *currently scheduled* time here 
    // using a persistence solution (like shared_preferences) to show the user their setting.
    // For simplicity, we initialize it to the default time (12:00 AM).
  }

  // --- Time Picker Logic ---

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime, // Start with the currently selected time
      helpText: 'اختر وقت التذكير اليومي',
      // Optional: Style the time picker for Arabic context
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
      
      // 1. Cancel any existing scheduled notification to avoid duplicates
      await _notificationService.cancelAllNotifications();

      // 2. Schedule the new notification with the user's chosen time
      await _notificationService.scheduleDailyNotification(
        hour: picked.hour,
        minute: picked.minute,
      );
      
      // Provide feedback to the user
      if (mounted) {
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
  }

  // --- Widget Build (UI) ---

  @override
  Widget build(BuildContext context) {
    // Helper function to format the TimeOfDay object nicely for the display
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
                      'وقت التذكير اليومي:',
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

            // 3. Optional: Cancel All Button
            OutlinedButton.icon(
              onPressed: () async {
                await _notificationService.cancelAllNotifications();
                setState(() {
                  // Reset displayed time to a neutral default after cancellation
                  _selectedTime = const TimeOfDay(hour: 0, minute: 0); 
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'تم إلغاء جميع التذكيرات بنجاح.',
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  );
                }
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
              'ملاحظة: يتم تكرار التذكير تلقائياً كل يوم في الوقت الذي تختاره.',
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