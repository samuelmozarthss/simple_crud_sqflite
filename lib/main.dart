import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CrudSqfLite());
}

class CrudSqfLite extends StatefulWidget {
  const CrudSqfLite({Key? key}) : super(key: key);

  @override
  State<CrudSqfLite> createState() => _CrudSqfLiteState();
}

class _CrudSqfLiteState extends State<CrudSqfLite> {
  TextEditingController textEditingController = TextEditingController();
  int? idSelecionado;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: textEditingController,
          ),
        ),
        body: Center(
            child: FutureBuilder<List<Mercearia>>(
          future: DatabaseHelper.instance.getMercearia(),
          builder:
              (BuildContext context, AsyncSnapshot<List<Mercearia>> snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Text('Carregando...'),
              );
            }
            return snapshot.data!.isEmpty
                ? const Center(
                    child: Text('Não há itens na mercearia'),
                  )
                : ListView(
                    children: snapshot.data!.map((mercearia) {
                      return Center(
                        child: Card(
                          color: idSelecionado == mercearia.id
                              ? Colors.amber.shade50
                              : Colors.amber.shade100,
                          child: ListTile(
                            title: Text(mercearia.nome),
                            onTap: () {
                              setState(() {
                                if (idSelecionado == null) {
                                  textEditingController.text = mercearia.nome;
                                  idSelecionado = mercearia.id;
                                } else {
                                  textEditingController.text = '';
                                  idSelecionado = null;
                                }
                              });
                            },
                            onLongPress: () {
                              setState(() {
                                DatabaseHelper.instance.remove(mercearia.id!);
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  );
          },
        )),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.save),
          onPressed: () async {
            idSelecionado != null
                ? await DatabaseHelper.instance.update(
                    Mercearia(
                        id: idSelecionado, nome: textEditingController.text),
                  )
                : await DatabaseHelper.instance.add(
                    Mercearia(nome: textEditingController.text),
                  );
            setState(() {
              textEditingController.clear();
              idSelecionado = null;
            });
            // print(textEditingController.text);
          },
        ),
      ),
    );
  }
}

class Mercearia {
  final int? id;
  final String nome;

  Mercearia({this.id, required this.nome});

  factory Mercearia.fromMap(Map<String, dynamic> json) => Mercearia(
        id: json['id'],
        nome: json['nome'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
    };
  }
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'mercearia.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE mercearia(
        id INTEGER PRIMARY KEY,
        nome TEXT) ''');
  }

  Future<List<Mercearia>> getMercearia() async {
    Database db = await instance.database;
    var mercearia = await db.query('mercearia', orderBy: 'nome');
    List<Mercearia> merceariaList = mercearia.isNotEmpty
        ? mercearia.map((c) => Mercearia.fromMap(c)).toList()
        : [];
    return merceariaList;
  }

  Future<int> add(Mercearia mercearia) async {
    Database db = await instance.database;
    return await db.insert('mercearia', mercearia.toMap());
  }

  Future<int> remove(int id) async {
    Database db = await instance.database;
    return await db.delete('mercearia', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(Mercearia mercearia) async {
    Database db = await instance.database;
    return await db.update('mercearia', mercearia.toMap(),
        where: 'id = ?', whereArgs: [mercearia.id]);
  }
}
