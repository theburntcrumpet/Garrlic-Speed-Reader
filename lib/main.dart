import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speed_reader/preferences.dart';
import 'package:path/path.dart' as p;

import 'reader.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garrlic Speed Reader',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.deepPurple,
      ),
      home: const MyHomePage(title: 'Garrlic Speed Reader'),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        /* dark theme settings */
      ),
      themeMode: ThemeMode.dark,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<SharedPreferences> sharedPreferences;
  @override
  void initState() {
    super.initState();
    sharedPreferences = SharedPreferences.getInstance();
  }
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(onPressed: (){Navigator.push(context,MaterialPageRoute(builder: (context) => Preferences()));}, icon: const Icon(Icons.settings))
        ],
      ),
      body: Column(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        children: [Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  child: Text(
                      'Previously Read', style: Theme.of(context).textTheme.titleLarge
                  ),)
                ],
            ),

          ],
        ),
          FutureBuilder<SharedPreferences>(
              future: sharedPreferences,
              builder: (context, snapshot){
                if (!snapshot.hasData) {
                  return Text("Could not fetch preferences!");
                }
                List<String> keys = (snapshot.data!.getStringList("keyList") ?? []);
                List<Widget> widgets = [];

                keys.reversed.forEach(
                        (s) {
                      double completedPercentage = (((snapshot.data!.getInt(s+"_progress") ?? 0) / (snapshot.data!.getInt(s+"_length") ?? 1)));
                      int wordsRemaining = ((snapshot.data!.getInt(s+"_length") ?? 1) - (snapshot.data!.getInt(s+"_progress") ?? 0) );
                      widgets.add(
                          Card(
                            child: Column(
                                children:[
                                  ListTile(
                                    onTap: ((){
                                      File file = File(s);
                                      if (!file.existsSync()){
                                        Fluttertoast.showToast(msg: "The file was moved or deleted");
                                        return;
                                      }
                                      Navigator.push(context,MaterialPageRoute(builder: (context) => Reader(file:file))).then((value) => setState(() {}));
                                    }),
                                    title: Text(p.basename(s)),
                                    subtitle: Text("${(wordsRemaining/(snapshot.data!.getInt("speed") ?? 450)).round()} Minutes Remaining"),
                                  ),
                                  LinearProgressIndicator(
                                    value: completedPercentage,
                                    semanticsLabel: 'Book Progress',
                                    color: Colors.deepPurple,
                                    backgroundColor: Theme.of(context).canvasColor,
                                  ),
                                ]
                            ),
                          )
                      );
                    }
                );
                return Expanded(
                    child:ListView(
                      shrinkWrap: true,
                      children: widgets,

                    ));
              })
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: openFile,
        tooltip: 'Open File',
        child: const Icon(Icons.folder),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void openFile() async{
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom,allowedExtensions:["txt", "pdf", "epub"]);
    if (result == null){
      Fluttertoast.showToast(msg: "No file selected!");
      return;
    }
    if (result.files.single.path == null) {
        Fluttertoast.showToast(msg: "File not found!");
        return;
    }
    File file = File(result.files.single.path ?? "");
    Navigator.push(context,MaterialPageRoute(builder: (context) => Reader(file:file))).then((value) => setState(() {}));
  }
}
