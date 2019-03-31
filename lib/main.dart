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
  runApp(MyApp());}
class MyApp extends StatefulWidget {
  @override
    MyAppState createState() {
    return new MyAppState();}}
class MyAppState extends State<MyApp> {
  var numberParts=4;
  var frozen=false;
  @override
    Widget build(BuildContext context){
    var value=numberParts.toDouble();
    return MaterialApp(
      title:'PizzaCutter',
      theme:ThemeData(primarySwatch:Colors.red,),
      home:Scaffold(appBar:AppBar(title:Text("PizzaCutter"),),
        body:Align(
          alignment:Alignment.topCenter,
          child:Container(
            child:Column(children:<Widget>[
              Camera(numberParts,frozen),
              Slider(value:value,onChanged:(change){setState((){numberParts=change.toInt();});},min:2,max:15,divisions:13,label:value.toString()),
              Expanded(child:Align(
                      alignment:Alignment.center,
                      child:InkResponse(
                        highlightShape:BoxShape.circle,
                        highlightColor:Colors.transparent,
                        radius:120.0/2,
                        child:IconButton(
                            iconSize:124.0,
                            onPressed:(){setState((){frozen=!frozen;});},
                            icon:Icon(Icons.pause)),)))],),),)));}}
class Camera extends StatefulWidget{
  final int numberParts;
  final bool frozen;
  Camera(this.numberParts,this.frozen);
  @override
  _Camera createState()=>_Camera();}
class _Camera extends State<Camera>{
  CameraController controller;
  double scale=1.0;
  var oldScale;
  bool firstUpdate=false;
  double firstScale;
  CameraImage lastImage;
  int id;
  Future<void> freezeFrame(int id)async=>await controller.takePicture(tempPath+"/"+id.toString());
  @override
  void initState(){
    super.initState();
    id=(Random().nextDouble()*10000).toInt();
    controller=CameraController(cameras[0],ResolutionPreset.medium);
    controller.initialize().then((_){
      if(!mounted){return;}
      setState((){});});}
  @override
  void dispose(){
    controller?.dispose();
    super.dispose();}
  @override
  void didUpdateWidget(Camera oldWidget){
    super.didUpdateWidget(oldWidget);
    if(oldWidget.frozen&&!widget.frozen){setState((){id=(Random().nextDouble()*10000).toInt();});}}
    @override
    Widget build(BuildContext context){
      if(!controller.value.isInitialized){
        return Container();}
      var widgets=<Widget>[];
      if (widget.frozen){
        widgets.add(FutureBuilder(
            future:freezeFrame(id),
            builder:(context,snapshot){
              if(File(tempPath+"/"+id.toString()).existsSync()){
                return Image.file(File(tempPath+"/"+id.toString()));
              }else{
                return Center(
                  child: CircularProgressIndicator(),);}}));
      }else{
        widgets.add(
            CameraPreview(controller));}
      widgets.add(GestureDetector(
        onScaleStart:(ScaleStartDetails details)=>firstUpdate=true,
        onScaleEnd:(ScaleEndDetails details)=>oldScale=scale,
        onScaleUpdate:(ScaleUpdateDetails details){
          if(firstUpdate){
            firstScale=details.scale;
            firstUpdate=false;}
          var futureScale=((details.scale/firstScale)-1)+oldScale;
          if(futureScale<=1.786&&futureScale>0.1){
            setState(()=>scale=futureScale);}},
        behavior:HitTestBehavior.translucent,
        child:Center(
          child:CustomPaint(
            painter:CirclePainter(widget.numberParts,scale),),),));
      return AspectRatio(
        aspectRatio:controller.value.aspectRatio,
        child:Stack(children:widgets, fit:StackFit.expand),);}}
class CirclePainter extends CustomPainter{
  var numberParts;
  double radius=150;
  double scale;
  @override
  void paint(Canvas canvas,Size size){
    Paint paint = Paint()
    ..color=Colors.white
    ..strokeCap=StrokeCap.round
    ..style=PaintingStyle.stroke
    ..strokeWidth=5.0;
    canvas.drawCircle(Offset.zero,radius*scale,paint);
    for(var i=0;i<numberParts;i++){canvas.drawLine(Offset.zero,Offset.fromDirection((((i+1)/numberParts)*2*pi)-(1/2)*pi,radius*scale),paint);}
    paint.color=Colors.black;
    paint.strokeWidth=2.0;
    canvas.drawCircle(Offset.zero,radius*scale+4.5,paint);}
  @override
  bool shouldRepaint(CustomPainter oldDelegate){return true;}
  CirclePainter(this.numberParts,[this.scale]);}