import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Pattern Singleton: garantisce che esista una sola istanza del database in tutta l'app
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('weekbite.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Se modificate le tabelle in futuro, aumentate la version (es. version: 2)
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // ==========================================================
  // 📐 CREAZIONE DELLE TABELLE (Punto di collaborazione del team)
  // ==========================================================
  Future _createDB(Database db, int version) async {
    
    // 1. TABELLA CACHE RICETTE VIRALI (Sostituisce SharedPreferences nel Main Screen)
    await db.execute('''
      CREATE TABLE viral_recipes_cache (
        id INTEGER PRIMARY KEY,
        title TEXT,
        image TEXT,
        recipe_json TEXT,
        fetch_date TEXT
      )
    ''');

    // 2. TABELLA PREFERITI (Salva i dati minimi per mostrare la card)
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY,
        title TEXT,
        image TEXT
      )
    ''');

    // 3. TABELLA RICETTE SALVATE + NOTE (Per il Recipe screen offline e le modifiche)
    await db.execute('''
      CREATE TABLE saved_recipes (
        id INTEGER PRIMARY KEY,
        title TEXT,
        image TEXT,
        recipe_json TEXT,
        personal_notes TEXT
      )
    ''');

    // Nota per i tuoi compagni: per aggiungere nuove tabelle basta accodare altri db.execute qui sotto!
    // Esempio:
    // await db.execute('CREATE TABLE dispensa (...)');
  }

  // ==========================================================
  // 🛒 OPERAZIONI 1: CACHE DELLE RICETTE VIRALI (MainScreen)
  // ==========================================================
  
  // Salva l'intera lista delle 30 ricette scaricate dall'API
  Future<void> saveViralCache(List<dynamic> recipesList, String todayDate) async {
    final db = await instance.database;
    
    // Puliamo la vecchia cache prima di inserire quella nuova
    await db.delete('viral_recipes_cache');

    for (var recipe in recipesList) {
      await db.insert(
        'viral_recipes_cache',
        {
          'id': recipe['id'],
          'title': recipe['title'],
          'image': recipe['image'],
          'recipe_json': json.encode(recipe), // Convertiamo la mappa in stringa primitiva
          'fetch_date': todayDate,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // Tenta di recuperare le ricette salvate oggi
  Future<List<dynamic>> getViralCache(String todayDate) async {
    final db = await instance.database;
    final res = await db.query(
      'viral_recipes_cache',
      where: 'fetch_date = ?',
      whereArgs: [todayDate],
    );

    if (res.isEmpty) return [];
    
    // Riconvertiamo le stringhe TEXT in oggetti JSON/Mappe per Flutter
    return res.map((row) => json.decode(row['recipe_json'] as String)).toList();
  }

  // ==========================================================
  // ❤️ OPERAZIONI 2: I PREFERITI (Recipe Screen / Profilo)
  // ==========================================================
  
  Future<void> addFavorite(int id, String title, String image) async {
    final db = await instance.database;
    await db.insert(
      'favorites',
      {'id': id, 'title': title, 'image': image},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFavorite(int id) async {
    final db = await instance.database;
    await db.delete('favorites', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isFavorite(int id) async {
    final db = await instance.database;
    final res = await db.query('favorites', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getAllFavorites() async {
    final db = await instance.database;
    return await db.query('favorites');
  }

  // ==========================================================
  // 💾 OPERAZIONI 3: RICETTE SALVATE LOCALI E NOTE (Recipe Screen)
  // ==========================================================
  
  // Quando l'utente clicca "Salva" e scarica la ricetta in locale
  Future<void> downloadRecipe(Map<String, dynamic> recipeData) async {
    final db = await instance.database;
    await db.insert(
      'saved_recipes',
      {
        'id': recipeData['id'],
        'title': recipeData['title'],
        'image': recipeData['image'],
        'recipe_json': json.encode(recipeData),
        'personal_notes': '', // All'inizio le note sono vuote
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Aggiorna o inserisce le note personali (Azione protetta se loggato)
  Future<void> updatePersonalNotes(int recipeId, String notes) async {
    final db = await instance.database;
    await db.update(
      'saved_recipes',
      {'personal_notes': notes},
      where: 'id = ?',
      whereArgs: [recipeId],
    );
  }

  // Controlla se la ricetta è già stata scaricata localmente
  Future<bool> isRecipeDownloaded(int id) async {
    final db = await instance.database;
    final res = await db.query('saved_recipes', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty;
  }

  // Recupera i dati di una specifica ricetta locale comprensiva di Note
  Future<Map<String, dynamic>?> getSavedRecipeWithNotes(int id) async {
    final db = await instance.database;
    final res = await db.query('saved_recipes', where: 'id = ?', whereArgs: [id]);
    
    if (res.isEmpty) return null;

    // Ricostruiamo la struttura dati iniettando le note aggiornate
    Map<String, dynamic> recipeData = json.decode(res.first['recipe_json'] as String);
    recipeData['personalNotes'] = res.first['personal_notes'];
    recipeData['isDownloadedLocal'] = true;
    
    return recipeData;
  }

  // Chiude il database in modo sicuro (buona pratica)
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}