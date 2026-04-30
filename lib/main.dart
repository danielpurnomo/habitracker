import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p; // Pakai prefix 'p' untuk menghindari error Context

void main() => runApp(const HabitrackerApp());

class HabitrackerApp extends StatelessWidget {
  const HabitrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'habitracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB71C1C),
          primary: const Color(0xFFB71C1C),
          surface: const Color(0xFFFFF8F8),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFB71C1C),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const HabitTrackerScreen(),
    );
  }
}

class Habit {
  final int? id;
  final String name;
  int isCompleted; 

  Habit({this.id, required this.name, this.isCompleted = 0});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'isCompleted': isCompleted};
  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
        id: map['id'],
        name: map['name'],
        isCompleted: map['isCompleted'],
      );
}

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await openDatabase(
      p.join(await getDatabasesPath(), 'habitracker_db.db'), // Menggunakan p.join
      onCreate: (db, version) => db.execute(
          'CREATE TABLE habits(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, isCompleted INTEGER)'),
      version: 1,
    );
    return _database!;
  }

  Future<void> insertHabit(Habit habit) async {
    final db = await database;
    await db.insert('habits', habit.toMap());
  }

  Future<List<Habit>> getHabits() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('habits');
    return List.generate(maps.length, (i) => Habit.fromMap(maps[i]));
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await database;
    await db.update('habits', habit.toMap(), where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<void> deleteHabit(int id) async {
    final db = await database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }
}

// --- 4. STATEFUL WIDGET (Halaman Utama) ---
class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _controller = TextEditingController();
  List<Habit> _habits = [];

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    final data = await _dbHelper.getHabits();
    setState(() {
      _habits = data;
    });
  }

  void _addHabit() async {
    if (_controller.text.isNotEmpty) {
      await _dbHelper.insertHabit(Habit(name: _controller.text));
      _controller.clear();
      _refreshData();
      if (mounted) Navigator.pop(context);
  }

  void _toggleHabit(Habit habit) async {
    habit.isCompleted = habit.isCompleted == 0 ? 1 : 0;
    await _dbHelper.updateHabit(habit);
    _refreshData();
  }

  void _deleteHabit(int id) async {
    await _dbHelper.deleteHabit(id);
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('habitracker')),
      body: _habits.isEmpty
          ? const Center(child: Text('Belum ada habit.'))
          : ListView.builder(
              itemCount: _habits.length,
              itemBuilder: (context, index) {
                return HabitTile(
                  habit: _habits[index],
                  onToggle: () => _toggleHabit(_habits[index]),
                  onDelete: () => _deleteHabit(_habits[index].id!),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context, //
            isScrollControlled: true,
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tambah Habit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  TextField(controller: _controller, autofocus: true),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: _addHabit, child: const Text('Simpan')),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- 5. STATELESS WIDGET (Komponen Item) ---
class HabitTile extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const HabitTile({super.key, required this.habit, required this.onToggle, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    bool isDone = habit.isCompleted == 1;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: ListTile(
        leading: Checkbox(
          value: isDone, 
          onChanged: (_) => onToggle(),
          activeColor: const Color(0xFFB71C1C),
        ),
        title: Text(
          habit.name,
          style: TextStyle(
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? Colors.grey : Colors.black87, // Fix typo blackDE
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}