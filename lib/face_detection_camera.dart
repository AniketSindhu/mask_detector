import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;
import 'package:firebase_admob/firebase_admob.dart';
import './boundary_box.dart';

class FaceDetectionFromLiveCamera extends StatefulWidget {
  @override
  _FaceDetectionFromLiveCameraState createState() =>
      _FaceDetectionFromLiveCameraState();
}

class _FaceDetectionFromLiveCameraState
    extends State<FaceDetectionFromLiveCamera> {
  List<CameraDescription> _availableCameras;
  CameraController cameraController;
  bool isDetecting = false;
  List<dynamic> _recognitions;
  int _imageHeight = 0;
  int _imageWidth = 0;
  bool front= true;
  InterstitialAd interstitialAd;
  @override
  void initState() {
    super.initState();
    FirebaseAdMob.instance.initialize(appId: 'ca-app-pub-8295782880270632~3798840407');
    interstitialAd = myInterstitial()..load()..show();
    loadModel();
    _getAvailableCameras();
  }
  @override
  void dispose() {
    cameraController?.dispose();
    interstitialAd.dispose();
    super.dispose();
  }
static MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
  keywords: <String>['apps', 'games', 'news'], // or MobileAdGender.female, MobileAdGender.unknown
  testDevices: <String>[], // Android emulators are considered test devices
);

InterstitialAd myInterstitial() {
    return InterstitialAd(
      adUnitId: 'ca-app-pub-8295782880270632/9789533681',
      targetingInfo: targetingInfo,
      listener: (MobileAdEvent event) {
        if (event == MobileAdEvent.failedToLoad) {
          interstitialAd..load();
        } else if (event == MobileAdEvent.closed) {
          interstitialAd = myInterstitial()..load();
        }
      },
    );
  }

 Future<void> _getAvailableCameras() async{
   WidgetsFlutterBinding.ensureInitialized();
   _availableCameras = await availableCameras();
   _initializeCamera(_availableCameras[1]);
 }

void loadModel() async {
    await Tflite.loadModel(
      model: "assets/model_unquant.tflite",
      labels: "assets/labels.txt",
    );
  }
   Future<void> _initializeCamera(CameraDescription description) async {
    cameraController = CameraController(description, ResolutionPreset.high);
  try {
    await cameraController.initialize().then(
      (_) {
        if (!mounted) {
          return;
        }
        cameraController.startImageStream(
          (CameraImage img) {
            if (!isDetecting) {
              isDetecting = true;
              Tflite.runModelOnFrame(
                bytesList: img.planes.map(
                  (plane) {
                    return plane.bytes;
                  },
                ).toList(),
                threshold: 0.5,
                rotation: 0,
                imageHeight: img.height,
                imageWidth: img.width,
                numResults: 1,
              ).then(
                (recognitions) {
                  setRecognitions(recognitions, img.height, img.width);
                  isDetecting = false;
                },
              );
            }
          },
        );
      },
    );
    setState((){}); 
  }
  catch(e){
    print(e);
  }  
}
  void _toggleCameraLens() {
 // get current lens direction (front / rear)
 final lensDirection =  cameraController.description.lensDirection;
 CameraDescription newDescription;
 if(lensDirection == CameraLensDirection.front){
    newDescription = _availableCameras.firstWhere((description) => description.lensDirection == CameraLensDirection.back);
 }
 else{
    newDescription = _availableCameras.firstWhere((description) => description.lensDirection == CameraLensDirection.front);
 }

  if(newDescription != null){
    _initializeCamera(newDescription);
  }
  else{
    print('Asked camera not available');
  }
}
  void setRecognitions(recognitions, imageHeight, imageWidth) {
    setState(() {
      _recognitions = recognitions;
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    return Container(
      constraints: const BoxConstraints.expand(),
      child: cameraController == null
          ? Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          : Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed:(){
                front==true?front=false:front=true;
                _toggleCameraLens();},
              child: Icon(front==true?Icons.camera_rear:Icons.camera_front),),
              backgroundColor: Colors.black,
              appBar:AppBar(
                title:Text("Mask detector"),
                centerTitle: true,
                backgroundColor: Colors.redAccent,),          
              body: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: cameraController.value.aspectRatio,
                      child: CameraPreview(cameraController),
                    ),
                  ),
                  BoundaryBox(
                      _recognitions == null ? [] : _recognitions,
                      math.max(_imageHeight, _imageWidth),
                      math.min(_imageHeight, _imageWidth),
                      screen.height,
                      screen.width),
                ],
              ),
          ),
    );
  }
}
