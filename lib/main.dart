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
  var nbPart=4;
  var frozen=false;
  @override
    Widget build(BuildContext context){
    var value=nbPart.toDouble();
    return MaterialApp(
      title:'PizzaCutter',
      theme:ThemeData(brightness:Brightness.dark,primaryColor:Colors.red),
      home:Scaffold(appBar:AppBar(title:Text("Pizza Cutter")),
        body:Align(
          alignment:Alignment.topCenter,
          child:Container(
            child:Column(children:<Widget>[
              Camera(nbPart,frozen),
              Slider(value:value,onChanged:(change){setState((){nbPart=change.toInt();});},min:2,max:20,divisions:18,label:nbPart.toString()),
              Expanded(child:Align(
                      alignment:Alignment.center,
                      child:InkResponse(
                        child:LayoutBuilder(builder: (c,cnstr) => IconButton(
                              iconSize:cnstr.biggest.height*.85,
                              onPressed:(){setState((){frozen=!frozen;});},
                              icon:Icon(frozen?Icons.play_arrow:Icons.pause)),
                        )))),
              Padding(padding:EdgeInsets.all(8),child: Text("Tip : Pinch the circle to scale it"),)])))));}}
class Camera extends StatefulWidget{
  final int nbParts;
  final bool frozen;
  Camera(this.nbParts,this.frozen);
  @override
  _Camera createState()=>_Camera();}
class _Camera extends State<Camera>{
  CameraController controller;
  double scl=1;
  double oldScl;
  bool frstUpd=false;
  double frstScl;
  CameraImage lastImg;
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
              }else{return Center(
                  child: CircularProgressIndicator());}}));
      }else{widgets.add(CameraPreview(controller));}
      widgets.add(GestureDetector(
        onScaleStart:(ScaleStartDetails details)=>frstUpd=true,
        onScaleEnd:(ScaleEndDetails details)=>oldScl=scl,
        onScaleUpdate:(ScaleUpdateDetails details){
          if(frstUpd){
            frstScl=details.scale;
            frstUpd=false;}
          var futureScale=((details.scale/frstScl)-1)+oldScl;
          if(futureScale<=1.78&&futureScale>.1){setState(()=>scl=futureScale);}},
        behavior:HitTestBehavior.translucent,
        child:Center(
          child:CustomPaint(
            painter:CrlcPaint(widget.nbParts,scl)))));
      return AspectRatio(
        aspectRatio:3/4,
        child:Stack(children:widgets,fit:StackFit.expand),);}}
class CrlcPaint extends CustomPainter{
  var numberParts;
  double radius=150;
  double scale;
  @override
  void paint(Canvas canvas,Size size){
    Paint paint = Paint()
    ..color=Colors.white
    ..strokeCap=StrokeCap.round
    ..style=PaintingStyle.stroke
    ..strokeWidth=5;
    canvas.drawCircle(Offset.zero,radius*scale,paint);
    for(var i=0;i<numberParts;i++){canvas.drawLine(Offset.zero,Offset.fromDirection((((i+1)/numberParts)*2*pi)-(1/2)*pi,radius*scale),paint);}
    paint.color=Colors.black;
    paint.strokeWidth=2;
    canvas.drawCircle(Offset.zero,radius*scale+4.5,paint);}
  @override
  bool shouldRepaint(CustomPainter oldDelegate){return true;}
  CrlcPaint(this.numberParts,[this.scale]);}