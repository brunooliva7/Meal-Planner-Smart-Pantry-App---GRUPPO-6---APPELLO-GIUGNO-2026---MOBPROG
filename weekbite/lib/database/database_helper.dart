import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:weekbite/screens/recipe_model.dart'; // Assicurati che il percorso sia corretto per il tuo progetto

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

    return await openDatabase(
      path,
      version: 2, // 🟢 BUMP ALLA VERSIONE 2 (FONDAMENTALE)
      onCreate: _createDB,
      onUpgrade: _onUpgrade, // 🟢 AGGIUNTO IL METODO DI AGGIORNAMENTO
      onConfigure: _onConfigure, 
    );
  }

  // Abilita il supporto nativo per le chiavi esterne in SQLite
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ==========================================================
  // 📐 CREAZIONE DELLE TABELLE DA ZERO (Per chi installa l'app ora)
  // ==========================================================
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE viral_recipes_cache (
        id INTEGER PRIMARY KEY,
        title TEXT,
        image TEXT,
        recipe_json TEXT,
        fetch_date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY,
        title TEXT,
        image TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE saved_recipes (
        id INTEGER PRIMARY KEY,
        title TEXT,
        image TEXT,
        recipe_json TEXT,
        personal_notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE planners (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        planner_id INTEGER NOT NULL,
        day TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        recipes_json TEXT NOT NULL,
        FOREIGN KEY (planner_id) REFERENCES planners (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        uid TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        name TEXT,
        photo_url TEXT,
        preferences_json TEXT,
        registration_date TEXT,
        password TEXT
      )
    ''');
  }

  // ==========================================================
  // ⬆️ AGGIORNAMENTO DEL DATABASE (Per te che lo avevi già installato)
  // ==========================================================
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Aggiunge la tabella users se si passa dalla versione 1 alla 2
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          uid TEXT PRIMARY KEY,
          email TEXT NOT NULL,
          name TEXT,
          photo_url TEXT,
          preferences_json TEXT,
          registration_date TEXT,
          password TEXT
        )
      ''');
    }
  }

  // ==========================================================
  // 🛒 OPERAZIONI 1: CACHE DELLE RICETTE VIRALI
  // ==========================================================
  Future<void> saveViralCache(List<dynamic> recipesList, String todayDate) async {
    final db = await instance.database;
    await db.delete('viral_recipes_cache');

    for (var recipe in recipesList) {
      await db.insert(
        'viral_recipes_cache',
        {
          'id': recipe['id'],
          'title': recipe['title'],
          'image': recipe['image'],
          'recipe_json': json.encode(recipe),
          'fetch_date': todayDate,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<dynamic>> getViralCache(String todayDate) async {
    final db = await instance.database;
    final res = await db.query(
      'viral_recipes_cache',
      where: 'fetch_date = ?',
      whereArgs: [todayDate],
    );

    if (res.isEmpty) return [];
    return res.map((row) => json.decode(row['recipe_json'] as String)).toList();
  }

  // ==========================================================
  // ❤️ OPERAZIONI 2: I PREFERITI
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
  // 💾 OPERAZIONI 3: RICETTE SALVATE LOCALI E NOTE
  // ==========================================================
  Future<void> downloadRecipe(Map<String, dynamic> recipeData) async {
    final db = await instance.database;
    await db.insert(
      'saved_recipes',
      {
        'id': recipeData['id'],
        'title': recipeData['title'],
        'image': recipeData['image'],
        'recipe_json': json.encode(recipeData),
        'personal_notes': recipeData['personalNotes'] ?? '', 
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updatePersonalNotes(int recipeId, String notes) async {
    final db = await instance.database;
    await db.update(
      'saved_recipes',
      {'personal_notes': notes},
      where: 'id = ?',
      whereArgs: [recipeId],
    );
  }

  Future<bool> isRecipeDownloaded(int id) async {
    final db = await instance.database;
    final res = await db.query('saved_recipes', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getSavedRecipeWithNotes(int id) async {
    final db = await instance.database;
    final res = await db.query('saved_recipes', where: 'id = ?', whereArgs: [id]);
    
    if (res.isEmpty) return null;

    Map<String, dynamic> recipeData = json.decode(res.first['recipe_json'] as String);
    recipeData['personalNotes'] = res.first['personal_notes'];
    recipeData['isDownloadedLocal'] = true;
    
    return recipeData;
  }

  // ==========================================================
  // 📅 OPERAZIONI 4: MEAL PLANNER
  // ==========================================================
  
  // 🟢 INSERIMENTO / SALVATAGGIO COMPLETO
  Future<void> saveFullPlanner(
    String name, 
    Map<String, List<String>> dayMealTypes, 
    Map<String, Map<String, List<RecipeModel>>> associatedRecipes
  ) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      int plannerId = await txn.insert('planners', {'name': name});

      for (var day in associatedRecipes.keys) {
        for (var mealType in associatedRecipes[day]!.keys) {
          List<RecipeModel> recipes = associatedRecipes[day]![mealType]!;
          
          String jsonRecipes = jsonEncode(recipes.map((r) => r.toMap()).toList());

          await txn.insert('meals', {
            'planner_id': plannerId,
            'day': day,
            'meal_type': mealType,
            'recipes_json': jsonRecipes
          });
        }
      }
    });
  }

  // 🟡 MODIFICA (UPDATE)
  Future<void> updatePlanner(
    int plannerId,
    String newName,
    Map<String, Map<String, List<RecipeModel>>> associatedRecipes
  ) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      await txn.update(
        'planners', 
        {'name': newName}, 
        where: 'id = ?', 
        whereArgs: [plannerId]
      );

      await txn.delete('meals', where: 'planner_id = ?', whereArgs: [plannerId]);

      for (var day in associatedRecipes.keys) {
        for (var mealType in associatedRecipes[day]!.keys) {
          String jsonRecipes = jsonEncode(
            associatedRecipes[day]![mealType]!.map((r) => r.toMap()).toList()
          );

          await txn.insert('meals', {
            'planner_id': plannerId,
            'day': day,
            'meal_type': mealType,
            'recipes_json': jsonRecipes
          });
        }
      }
    });
  }

  // 🔵 LETTURA (FETCH) SPECIFICA
  Future<Map<String, dynamic>?> getPlannerComplete(String name) async {
    final db = await instance.database;

    final plannerRes = await db.query('planners', where: 'name = ?', whereArgs: [name]);
    if (plannerRes.isEmpty) return null;

    final planner = plannerRes.first;
    int plannerId = planner['id'] as int;

    final mealsRes = await db.query('meals', where: 'planner_id = ?', whereArgs: [plannerId]);

    Map<String, List<String>> dayMealTypes = {};
    Map<String, Map<String, List<RecipeModel>>> associatedRecipes = {};

    for (var row in mealsRes) {
      String day = row['day'] as String;
      String mealType = row['meal_type'] as String;
      String jsonStr = row['recipes_json'] as String;

      List<dynamic> decodedList = jsonDecode(jsonStr);
      List<RecipeModel> recipes = decodedList.map((m) => RecipeModel.fromJson(m)).toList();

      dayMealTypes.putIfAbsent(day, () => []).add(mealType);
      associatedRecipes.putIfAbsent(day, () => {});
      associatedRecipes[day]![mealType] = recipes;
    }

    return {
      'id': plannerId,
      'name': name,
      'dayMealTypes': dayMealTypes,
      'associatedRecipes': associatedRecipes
    };
  }
 
  // Recupera solo i nomi (per la lista di scelta)
  Future<List<String>> getAllPlannerNames() async {
    final db = await instance.database;
    final res = await db.query('planners');
    return res.map((row) => row['name'] as String).toList();
  }

  // Elimina un planner
  Future<int> deletePlanner(int id) async {
    final db = await instance.database;
    return await db.delete('planners', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================================
  // 👤 OPERAZIONI UTENTE
  // ==========================================================
  Future<void> saveOrUpdateUser(Map<String, dynamic> userData) async {
    final db = await instance.database;
    
    await db.insert(
      'users',
      {
        'uid': userData['uid'],
        'email': userData['email'],
        'name': userData['name'],
        'photo_url': userData['photo_url'],
        'preferences_json': userData['preferences_json'] ?? '{}',
        'registration_date': DateTime.now().toIso8601String(),
        'password': userData['password'], // Aggiunto per salvare la password
      },
      conflictAlgorithm: ConflictAlgorithm.replace, 
    );
  }

  // 🟢 SALVA LA CACHE DELLA DISPENSA
  Future<void> savePantryCache(List<dynamic> recipes, String dateStr) async {
    final db = await instance.database;
    // Pulisce la cache dei giorni precedenti
    await db.delete('api_cache', where: 'cache_date != ? AND cache_type = ?', whereArgs: [dateStr, 'pantry']);
    
    for (var recipe in recipes) {
      await db.insert('api_cache', {
        'recipe_id': recipe['id'] ?? 0,
        'cache_date': dateStr,
        'cache_type': 'pantry', // <-- Tag specifico per non mischiarle con le virali
        'data_json': jsonEncode(recipe),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // 🟢 LEGGE LA CACHE DELLA DISPENSA DEL GIORNO ATTUALE
  Future<List<dynamic>> getPantryCache(String dateStr) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'api_cache',
      where: 'cache_date = ? AND cache_type = ?',
      whereArgs: [dateStr, 'pantry'],
    );
    return maps.map((e) => jsonDecode(e['data_json'] as String)).toList();
  }

  // ==========================================================
  // CHIUSURA DATABASE
  // ==========================================================
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}