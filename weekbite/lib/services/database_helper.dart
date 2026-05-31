import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:weekbite/screens/recipe_model.dart';
import 'package:weekbite/screens/ingredienti_model.dart';

class DatabaseHelper {
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
      version: 4, // 🟢 BUMP ALLA VERSIONE 4 PER FORZARE L'AGGIORNAMENTO
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure, 
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // ==========================================================
  // 📐 CREAZIONE DELLE TABELLE DA ZERO (Nuovi Utenti)
  // ==========================================================
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT,
        nickname TEXT
      )
    ''');
  
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_profiles (
        user_id INTEGER PRIMARY KEY,
        peso REAL,
        altezza REAL,
        bio TEXT,
        image_path TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        id INTEGER PRIMARY KEY,
        title TEXT,
        image TEXT,
        user_id INTEGER,
        foreign key (user_id) references user(user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS saved_recipes (
        id INTEGER PRIMARY KEY,
        title TEXT,
        image TEXT,
        servings INTEGER,
        readyInMinutes INTEGER,
        summary TEXT,
        instructions TEXT,
        extendedIngredients TEXT,
        personal_notes TEXT,
        recipe_json TEXT,
        user_id INTEGER,
        foreign key (user_id) references user(user_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS planners (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS meals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        planner_id INTEGER NOT NULL,
        day TEXT NOT NULL,
        meal_type TEXT NOT NULL,
        recipes_json TEXT NOT NULL,
        FOREIGN KEY (planner_id) REFERENCES planners (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS dispensa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        quantita REAL,
        unitaMisura TEXT,
        pezzi INTEGER,
        categoria TEXT,
        dataScadenza TEXT,
        fk_utente INT,
        FOREIGN KEY(fk_utente) REFERENCES users(id) ON DELETE CASCADE        
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS lista_spesa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        quantita REAL,
        unitaMisura TEXT,
        pezzi INTEGER,
        categoria TEXT,
        dataScadenza TEXT,
        fk_utente INT,
        FOREIGN KEY(fk_utente) REFERENCES users(id) ON DELETE CASCADE        
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS api_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER,
        cache_date TEXT,
        cache_type TEXT,
        data_json TEXT,
        user_id INTEGER,
        foreign key (user_id) references user(user_id)
      )
    ''');

    // 🟢 AGGIUNTA LA TABELLA MANCANTE PER LE RICETTE VIRALI
    await db.execute('''
      CREATE TABLE IF NOT EXISTS viral_recipes_cache (
        id INTEGER PRIMARY KEY,
        title TEXT,
        image TEXT,
        recipe_json TEXT,
        fetch_date TEXT,
        user_id INTEGER,
        foreign key (user_id) references user(user_id)
      )
    ''');
  }

  // ==========================================================
  // ⬆️ AGGIORNAMENTO DEL DATABASE (Vecchi Utenti)
  // ==========================================================
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Forza la creazione di TUTTE le tabelle mancanti in modo sicuro
    await _createDB(db, newVersion);
    
    // Se c'è la vecchia tabella "users" corrotta (con uid TEXT), 
    // l'ideale in fase di sviluppo è ricrearla per allinearla al nuovo modello.
    // Nota: in produzione servirebbe una migrazione complessa, ma qui evitiamo crash.
    if (oldVersion < 4) {
      try {
        // Tentativo di aggiungere la colonna nickname se mancante nei vecchi DB
        await db.execute("ALTER TABLE users ADD COLUMN nickname TEXT;");
      } catch (e) {
        // Ignora l'errore se la colonna esiste già o la tabella ha uno schema troppo diverso
        print("Migrazione colonna nickname: ${e.toString()}");
      }
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
 
  Future<List<String>> getAllPlannerNames() async {
    final db = await instance.database;
    final res = await db.query('planners');
    return res.map((row) => row['name'] as String).toList();
  }

  Future<int> deletePlanner(int id) async {
    final db = await instance.database;
    return await db.delete('planners', where: 'id = ?', whereArgs: [id]);
  }

  // ==========================================================
  // 👤 OPERAZIONI UTENTE
  // ==========================================================
  
  // 🟢 FUNZIONE ALLINEATA: Ora utilizza i campi corretti della tabella `users` (id, name, email, password, nickname)
  Future<void> saveOrUpdateUser(Map<String, dynamic> userData) async {
    final db = await instance.database;
    
    // Inseriamo i dati rispettando lo schema corretto definito in _createDB
    await db.insert(
      'users',
      {
        'name': userData['name'] ?? 'Utente',
        'email': userData['email'],
        'password': userData['password'] ?? '', 
        'nickname': userData['nickname'] ?? userData['email'].toString().split('@').first,
      },
      conflictAlgorithm: ConflictAlgorithm.replace, 
    );
  }

  // 🟢 SALVA LA CACHE DELLA DISPENSA E ALTRE FUNZIONI ESISTENTI...
  Future<void> savePantryCache(List<dynamic> recipes, String dateStr) async {
    final db = await instance.database;
    await db.delete('api_cache', where: 'cache_date != ? AND cache_type = ?', whereArgs: [dateStr, 'pantry']);
    
    for (var recipe in recipes) {
      await db.insert('api_cache', {
        'recipe_id': recipe['id'] ?? 0,
        'cache_date': dateStr,
        'cache_type': 'pantry', 
        'data_json': jsonEncode(recipe),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<Ingredienti> addIngrediente(String nomeTabella, Ingredienti ingrediente, int userId) async {
    final db = await instance.database;

    final List<Map<String, dynamic>> esistentiMap = await db.query(
      nomeTabella,
      where: 'LOWER(nome) = LOWER(?) AND fk_utente = ?',
      whereArgs: [ingrediente.nome.trim(), userId],
    );

    final List<Ingredienti> esistenti = esistentiMap.map((row) => Ingredienti.fromMap(row)).toList();
    Ingredienti? matchTrovato;

    DateTime dataNuova = DateTime(ingrediente.dataScadenza.year, ingrediente.dataScadenza.month, ingrediente.dataScadenza.day);

    for (var esistente in esistenti) {
      DateTime dataEsistente = DateTime(esistente.dataScadenza.year, esistente.dataScadenza.month, esistente.dataScadenza.day);

      if (esistente.quantita == ingrediente.quantita &&
          esistente.unitaMisura == ingrediente.unitaMisura &&
          esistente.categoria == ingrediente.categoria &&
          dataEsistente.isAtSameMomentAs(dataNuova)) {
        matchTrovato = esistente;
        break;
      }
    }

    if (matchTrovato != null) {
      matchTrovato.pezzi += ingrediente.pezzi; 
      await updateIngrediente(nomeTabella, matchTrovato);
      return matchTrovato; 
    }

    final ingredienteMap = ingrediente.toMap();
    ingredienteMap.remove('id'); 
    ingredienteMap['fk_utente'] = userId;

    final id = await db.insert(nomeTabella, ingredienteMap);
    ingrediente.id = id; 
    
    return ingrediente;
  }

 Future<List<Ingredienti>> getIngredienti(String nomeTabella, int userId) async {
    final db = await instance.database;
    final result = await db.query(
      nomeTabella,
      where: 'fk_utente = ?',
      whereArgs: [userId]
    );
    return result.map((json) => Ingredienti.fromMap(json)).toList();
  }

  Future<List<String>> getDispensaIngredient(int userId) async {
    final db = await instance.database;
    final res = await db.query(
      'dispensa', 
      columns: ['nome'],
      where: 'fk_utente = ?',
      whereArgs: [userId]
    );
    return res.map((row) => row['nome'] as String).toList();
  }

  Future<int> deleteIngrediente(String nomeTabella, int id) async {
    final db = await instance.database;
    return await db.delete(nomeTabella, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateIngrediente(String nomeTabella, Ingredienti ingrediente) async {
    if (ingrediente.id == null) return 0; 
    final db = await instance.database;
    return await db.update(
      nomeTabella,
      ingrediente.toMap(),
      where: 'id = ?',
      whereArgs: [ingrediente.id],
    );
  }

  Future<List<dynamic>> getPantryCache(String dateStr) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'api_cache',
      where: 'cache_date = ? AND cache_type = ?',
      whereArgs: [dateStr, 'pantry'],
    );
    return maps.map((e) => jsonDecode(e['data_json'] as String)).toList();
  }

  Future<List<String>> getDispensaIngredients() async {
    final db = await instance.database;
    final res = await db.query('dispensa', columns: ['nome']);
    return res.map((row) => row['nome'] as String).toList();
  }

  Future<void> deleteRecipe(int id) async {
  final db = await database;
  await db.delete('downloaded_recipes', where: 'id = ?', whereArgs: [id]); 
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}