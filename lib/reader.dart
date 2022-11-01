import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:pdf_text/pdf_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';
class Reader extends StatefulWidget {
  const Reader({Key? key, required this.file}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final File file;

  @override
  State<Reader> createState() => _ReaderState();
}

class _ReaderState extends State<Reader> {
  int _currentIndex = 0;
  bool playing = false;
  List<String> fileWords = [];
  int wordsPerMinute = 450;
  int timerDelay = 0;
  Timer? timer;
  Future<SharedPreferences> sharedPreferences = SharedPreferences.getInstance();
  @override
  void initState() {
    Wakelock.enable();
    super.initState();
    loadPreferences();
    loadProgress();
    if(p.extension(widget.file.path) == ".epub"){
      loadEpub(widget.file.readAsBytesSync());
    } else if (p.extension(widget.file.path) == ".pdf"){
      loadPdf();
    }
    else {
      fileWords = getFileWords(widget.file.readAsStringSync());
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
              onPressed: ()=>incrementPosition(-wordsPerMinute),
              child:Text("👈 1M"),
              style:TextButton.styleFrom(
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                primary: Colors.white
              )
          ),
          TextButton(
              onPressed: ()=>setPosition(0),
              child:Text("🐣 Start"),
              style:TextButton.styleFrom(
                  backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                  primary: Colors.white
              )
          ),
          TextButton(
              onPressed: ()=>setPosition(fileWords.length-1),
              child:Text("🍗 End"),
              style:TextButton.styleFrom(
                  backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                  primary: Colors.white
              )
          ),
          TextButton(
              onPressed: ()=>incrementPosition(wordsPerMinute),
              child:Text("👉 1M"),
              style:TextButton.styleFrom(
                  backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                  primary: Colors.white
              )
          ),
        ],
      ),
      body: Center(
            child: InkWell(
                onTap: togglePlaying,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(_currentIndex < fileWords.length ? fileWords[_currentIndex] : "** Loading Document **" ,style: Theme.of(context).textTheme.displayMedium, ),
                        )

                      ],
                    ),
                    LinearProgressIndicator(
                      value: _currentIndex/(fileWords.length-1),
                      semanticsLabel: 'Book Progress',
                      color: Colors.deepPurple,
                      backgroundColor: Theme.of(context).canvasColor,
                    ),

                  ],

                )
            )
        )

      );
  }

  void togglePlaying(){
    saveProgress();
    playing = !playing;
    if (timer == null && playing)
      timer = Timer.periodic(Duration(milliseconds: ((60 / wordsPerMinute) * 1000).round()), (Timer t) => nextWord());
    if(!playing){
      timer!.cancel();
      timer = null;
    }

  }

  void nextWord(){
    setState((){
      if(playing && _currentIndex < fileWords.length-1)
        _currentIndex+=1;
    });
    if(_currentIndex % 100 == 0){
      saveProgress();
    }
  }
  
  void incrementPosition(int incrementBy) {
    setState(() {
      if (_currentIndex + incrementBy < 0) {
        _currentIndex = 0;
        return;
      }

      if (_currentIndex + incrementBy > fileWords.length - 1) {
        _currentIndex = fileWords.length - 1;
        return;
      }
      _currentIndex += incrementBy;
    });
  }

  void setPosition(int position){
    setState((){
      _currentIndex = position;
    });
  }

  void loadEpub(List<int> data) async{
    EpubBook epub = await EpubReader.readBook(data);
    String s = "";
    EpubContent ? content = epub.Content;
    Map<String, EpubTextContentFile> ? htmlFiles = content!.Html;
    if (htmlFiles == null)
      {
        return;
      }
    htmlFiles.values.forEach((EpubTextContentFile htmlFile) {
      s+=Bidi.stripHtmlIfNeeded(htmlFile.Content ?? "");
    });
    setState((){
      fileWords = getFileWords(s);
    });
  }

  void loadPdf() async{
    PDFDoc doc = await PDFDoc.fromFile(widget.file);
    String docText = await doc.text;
    setState(() {
      fileWords = getFileWords(docText);
    });
  }

  void saveProgress() {
    String key = widget.file.path;
    String progressKey = key+"_progress";
    String lengthKey = key+"_length";
    sharedPreferences.then(
        (s){
          List<String> ? keyList = s.getStringList("keyList");
          if(keyList == null){
            keyList = [key];
            s.setStringList("keyList", keyList);
          } else{
            keyList.remove(key);
            keyList.add(key);
            s.setStringList("keyList", keyList);
          }

          s.setInt(progressKey, _currentIndex);
          s.setInt(lengthKey, fileWords.length-1);
        }
    );
  }

  void loadProgress() {
    String key = widget.file.path;
    String progressKey = key+"_progress";
    sharedPreferences.then((s){
      setState(() {
        _currentIndex = s.getInt(progressKey) ?? 0;
      });

    });
  }

  void loadPreferences(){
    setState(() {
      sharedPreferences.then((s){
        wordsPerMinute = s.getInt("speed") ?? 450;
      });
    });
  }

  List<String> getFileWords(String book){
    List<String> words = [];
    words = book.replaceAll("\t"," ").replaceAll("\n", " ").replaceAll("\r", " ").replaceAll("  ", " ").split(" ");

    setState((){
      words.removeWhere((String s) => s.isEmpty);
    });
    return words;
  }

  @override
  void dispose() {
    super.dispose();
    if(timer!=null){
      timer!.cancel();
    }
    saveProgress();
  }

}



