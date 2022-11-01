import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preferences extends StatefulWidget {
  const Preferences({Key? key}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<Preferences> createState() => _PreferencesState();
}

class _PreferencesState extends State<Preferences> {
  TextEditingController speedController = TextEditingController();
  late Future<SharedPreferences> sharedPreferences;
  @override
  void initState(){
    speedController.text = "450";
    sharedPreferences = SharedPreferences.getInstance();
    loadPreferences();
  }
  @override
  Widget build(BuildContext buildContext){
    return Scaffold(
      appBar: AppBar(title: Text("Preferences")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child:
            TextFormField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              controller: speedController,
              validator: (t){
                int ? i = int.tryParse(t??"450");
                if (i == null){
                  return "Enter a valid number";
                }
                if ( i < 50 || i > 1000)
                {
                  return "Value must be between 50 and 1000";
                }
              },
              autovalidateMode: AutovalidateMode.always,
              decoration: InputDecoration(labelText:"Words per minute"),
            ))
          ],
        )
      )
    );
  }

  void savePreferences(){
    sharedPreferences.then((value) {
      int i = int.tryParse(speedController.text) ?? 450;
      if (i < 50){
        i = 50;
      }
      if (i > 1000) {
        i = 1000;
      }

      value.setInt("speed", i);
    }
    );
  }

  void loadPreferences() async{
    setState(() {
      sharedPreferences.then((s){
        speedController.text = (s.getInt("speed") ?? 450).toString();
      });
    });
  }

  @override
  void dispose(){
    super.dispose();
    savePreferences();
  }
}
