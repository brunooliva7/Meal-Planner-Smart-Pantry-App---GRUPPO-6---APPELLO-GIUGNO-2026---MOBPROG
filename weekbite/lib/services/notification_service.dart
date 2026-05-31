import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzData.initializeTimeZones();
    
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/icona_notifica');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    
    await _notificationsPlugin.initialize(initSettings);
    
    _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  static Future<void> schedulaNotificaScadenza(int id, String nomeProdotto, DateTime dataScadenza) async {
    try {
      final dataNotifica = dataScadenza.subtract(const Duration(days: 3));
      final dataNotificaDefinitiva = DateTime(dataNotifica.year, dataNotifica.month, dataNotifica.day, 9, 00);

      if (dataNotificaDefinitiva.isBefore(DateTime.now())) return;

      await _notificationsPlugin.zonedSchedule(
        id, 
        'Sta per scadere!',
        'Il prodotto "$nomeProdotto" scade a breve!',
        tz.TZDateTime.from(dataNotificaDefinitiva, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'scadenze_channel',
            'Scadenze Prodotti  ',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      print("Notifica programmata per: $dataNotificaDefinitiva"); 

    } catch (e) {
      print("Errore: $e");
    }
  }
  static Future<void> cancellaNotifica(int id) async {
    await _notificationsPlugin.cancel(id);
    print("🗑️ Notifica $id annullata.");
  }
}