import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  // Inizializza il servizio (da chiamare nel main.dart)
  static Future<void> init() async {
    tzData.initializeTimeZones();
    
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/icona_notifica');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    
    await _notificationsPlugin.initialize(initSettings);
    
    // Richiede i permessi per Android 13 o superiori
    _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  // Schedula la notifica 3 giorni prima della scadenza
  static Future<void> schedulaNotificaScadenza(int id, String nomeProdotto, DateTime dataScadenza) async {
    // Calcola la data della notifica (Data Scadenza - 3 Giorni)
    final dataNotifica = dataScadenza.subtract(const Duration(days: 3));
    // Imposta la notifica per le 09:00 del mattino
    final dataNotificaDefinitiva = DateTime(dataNotifica.year, dataNotifica.month, dataNotifica.day, 9, 0);

    // Se la data della notifica è già passata (es. il prodotto scade domani), non schedulare nulla
    if (dataNotificaDefinitiva.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      id, // Usiamo l'ID del database così ogni notifica è unica
      'Attenzione alla scadenza! ⏰',
      'Il tuo prodotto "$nomeProdotto" scade tra 3 giorni! Consumalo prima.',
      tz.TZDateTime.from(dataNotificaDefinitiva, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'scadenze_channel',
          'Scadenze Prodotti',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
  // 🟢 AGGIUNGI QUESTA FUNZIONE PER IL TEST
  static Future<void> mostraNotificaDiTest() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifiche',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails dettagli = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      999, // ID fittizio
      '🚀 Test Notifica!',
      'Se stai leggendo questo messaggio, il motore delle notifiche funziona alla grande!',
      dettagli,
    );
  }

  // Cancella la notifica (se consumi o elimini il prodotto prima che scada)
  static Future<void> cancellaNotifica(int id) async {
    await _notificationsPlugin.cancel(id);
  }
}