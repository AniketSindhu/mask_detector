import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mask detector',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
bool _loading;
List _outputs;
File _image;
void initState() {
    super.initState();
    _loading = true;
    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
}
loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
}
pickImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    setState(() {
      _loading = true;
      //Declare File _image in the class which is used to display the image on the screen. 
      _image = image; 
    });
    classifyImage(image);
  }
classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _loading = false;
      //Declare List _outputs in the class which will be used to show the classified classs name and confidence
      _outputs = output;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title:Text("Mask detector"),
        centerTitle: true,
        backgroundColor: Colors.redAccent,),
        floatingActionButton: FloatingActionButton(
        onPressed: pickImage,
        child: Icon(Icons.image),
      ),
      body: _loading 
          ? Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          : Container(
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _image == null ? Container() : Image.file(_image,fit: BoxFit.contain,height:MediaQuery.of(context).size.height*0.5),
                  SizedBox(
                    height: 10,
                  ),
                  _outputs != null
                      ? Column(
                        children: <Widget>[
                          Text(
                              _outputs[0]["label"]=='0 mask'?"Mask detected":"Mask not detected",
                              style: TextStyle(
                                color: _outputs[0]["label"]=='0 mask'?Colors.green:Colors.red,
                                fontSize: 25.0,
                              ),
                            ),
                          Text("${(_outputs[0]["confidence"]*100).round()}%",style: TextStyle(color:Colors.purpleAccent,fontSize:20),)
                        ],
                      )
                      : Text("Classification Failed")
                ],
              ),
            )
    );
  }
}