import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import "package:path_provider/path_provider.dart";
List<CameraDescription> cameras;
Directory tempDir;
String tempPath;
Future<void> main() async{
  cameras = await availableCameras();
  tempDir = await getTemporaryDirectory();
  tempPath = tempDir.path;
  runApp(MyApp());
}
class MyApp extends StatefulWidget {
  @override
    MyAppState createState() {
    return new MyAppState();
  }
}
class MyAppState extends State<MyApp> {
  var numberParts = 4;
  var frozen = false;
  @override
    Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text("AppTestCut"),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: Container(
            child: Column(children: <Widget>[
              CameraWidget(numberParts, frozen),
              SliderContainer((change){
                setState(() {
                  numberParts = change.toInt();
                });
              },numberParts.toDouble()),
              Expanded(
                  child: Align(
                      alignment: Alignment.center,
                      child: InkResponse(
                        onTap: ()=>print("Tap"),
                        containedInkWell: false,
                        highlightShape: BoxShape.circle,
                        highlightColor: Colors.transparent,
                        radius: 120.0/2,
                        child: IconButton(
                            iconSize: 124.0,
                            onPressed: (){
                              setState(() {
                                if(!frozen){
                                  frozen = true;
                                }else{
                                  frozen = false;
                                }
                              });
                            },
                            icon: Icon(Icons.pause)),
                      )))
            ],),
          ),
        )
      )
    );
  }
}
class CameraWidget extends StatefulWidget {
  final int numberParts;
  final bool frozen;
  CameraWidget(this.numberParts, this.frozen);
  @override
  _CameraWidgetState createState() => _CameraWidgetState();
}
class _CameraWidgetState extends State<CameraWidget>{
  CameraController controller;
  double scale = 1.0;
  var oldScale = 1.0;
  bool firstUpdate = false;
  double firstScale = 1.0;
  CameraImage lastImage;
  int id;
  bool needNewStream = true;
  @override
  void initState() {
    super.initState();
    //id = widget.id;
    id = (Random().nextDouble() * 10000).toInt();
    controller = CameraController(cameras[0], ResolutionPreset.medium);
    controller.initialize().then((_){
      if(!mounted) {
        return;
      }
      setState(() {
      });
    });
  }
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
  @override
  void didUpdateWidget(CameraWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(oldWidget.frozen && !widget.frozen){//Si le widget n'est plus gelé, on supprime l'ancienne photo
      try{
        File(tempPath + "/" +id.toString()).delete();
      }catch(e){
        print(e);
      }
      setState(() {
        id = (Random().nextDouble() * 10000).toInt();
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    if(!controller.value.isInitialized){
      return Container();
    }
    var widgets = <Widget>[];
    if(widget.frozen && needNewStream){
      print("WIDGET FROZE");
      widgets.add(FutureBuilder(
        future : freezeFrame(id),
        builder: (context, snapshot){
          print("FUTURE");
          print(Directory(tempPath).listSync());
          if(File(tempPath+ "/"  + id.toString()).existsSync()) {
            return Image.file(File(tempPath+ "/"  + id.toString()));
          }else{
            return Center(
              child: CircularProgressIndicator(),
            );
          }
      }));
    }else if(widget.frozen && !needNewStream){
      print(id.toString());
      print("ALREADY FROZEN BUILD");
      widgets.add(Image.file(File(tempPath+ "/"  + id.toString())));
    }else{
      print(Directory(tempPath).listSync());
      widgets.add(
          CameraPreview(controller)
      );
    }
    widgets.add(GestureDetector(
      onScaleStart: (ScaleStartDetails details){
        print("Start");
        firstUpdate = true;
      },
      onScaleEnd: (ScaleEndDetails details){
        print("End");
        oldScale = scale;
      },
      onScaleUpdate: (ScaleUpdateDetails details){
        if(firstUpdate){
          firstScale = details.scale;
          firstUpdate = false;
        }
        var futureScale = ((details.scale/firstScale) - 1) + oldScale;
        //var futureScale = (details.scale + oldScale - 1;
        if (futureScale <= 1.786 && futureScale > 0.1) {
          setState(() {
            scale = futureScale;
          });
        }
      },
      onTap: ()=>print("TAP"),
      behavior: HitTestBehavior.translucent,
      child: Center(
        child: CustomPaint(
          painter: CirclePainter(widget.numberParts, scale),
        ),
      ),
    ));
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: Stack(
          children: widgets,
          fit: StackFit.expand),
    );
  }
  Future<void> freezeFrame(int id) async{
    print(tempPath);
    try{
      print(tempPath + "/"  + id.toString());
      await controller.takePicture(tempPath + "/" + id.toString());
    }catch(e){
      print(e);
    }
  }
}
class CirclePainter extends CustomPainter{
  var numberParts;
  double radius = 150;
  double scale;
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
    ..color = Colors.white
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5.0;
    Paint paintBorder = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset.zero, radius * scale, paint);
    canvas.drawCircle(Offset.zero, radius * scale + 4.5, paintBorder);
    for (var i = 0; i<numberParts; i++){
      canvas.drawLine(Offset.zero, Offset.fromDirection((((i+1)/numberParts)*2*pi) - (1/2)*pi,radius*scale), paint);
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate ) {
    if(scale != 1.0){
      return true;
    }else{
      return false;
    }
  }
  CirclePainter(this.numberParts, [this.scale]);
}
class SliderContainer extends StatelessWidget{
  final Function(double value) onNumberPartsChanged;
  final double value;
  SliderContainer(this.onNumberPartsChanged, this.value);
  @override
  Widget build(BuildContext context) {
    return Slider(
      value: value,
      onChanged: (change){
        onNumberPartsChanged(change);
      },
      min: 2,
      max: 15,
      divisions: 13,
      label: value.toInt().toString(),
    );
  }
}