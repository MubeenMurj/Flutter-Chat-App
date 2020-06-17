import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:image_picker_saver/image_picker_saver.dart';
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';

class FullPhoto extends StatefulWidget {
  final String url;

  FullPhoto({Key key, @required this.url}) : super(key: key);

  @override
  _FullPhotoState createState() => _FullPhotoState();
}

class _FullPhotoState extends State<FullPhoto> {
  double contHeight = 0, contWidth = 0;
  bool downloading = false;
  IconData downloadIcon = Feather.download;

  void hideText() {
    Future.delayed(
      Duration(seconds: 2),
      () {
        setState(() {
          contHeight = contWidth = 0;
          downloadIcon = Feather.download;
        });
      },
    );
  }

  void downloadImage() async {
    var response = await http.get(widget.url);

    debugPrint(response.statusCode.toString());

    var filePath =
        await ImagePickerSaver.saveFile(fileData: response.bodyBytes);

    var savedFile = File.fromUri(Uri.file(filePath));
    setState(() {
      Future<File>.sync(() => savedFile);
      downloading = false;
      contWidth = 85;
      contHeight = 20;
      downloadIcon = Feather.check_circle;
    });
    hideText();
  }

  void dialogShow() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Column(
          children: <Widget>[
            Icon(
              AntDesign.check,
              color: Theme.of(context).accentColor,
            ),
            Text(
              'Image saved in Pictures folder.',
              style: TextStyle(color: Colors.black38),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: Stack(
        children: <Widget>[
          FullPhotoScreen(url: widget.url),
          Padding(
            padding: EdgeInsets.only(top: 30.0),
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 0,
                color: Theme.of(context).accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                      left: 30, right: 10.0, top: 10.0, bottom: 10.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Back',
                        icon: Icon(Ionicons.md_arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      !downloading
                          ? IconButton(
                              tooltip: 'Save Image',
                              icon: Icon(
                                downloadIcon,
                              ),
                              onPressed: () {
                                setState(() {
                                  downloading = true;
                                });
                                downloadImage();
                              },
                            )
                          : CircularProgressIndicator(
                              backgroundColor: Colors.black,
                            ),
                      AnimatedContainer(
                        width: contWidth,
                        height: contHeight,
                        duration: Duration(milliseconds: 500),
                        child: Text(
                          'Downloaded!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FullPhotoScreen extends StatefulWidget {
  final String url;

  FullPhotoScreen({Key key, @required this.url}) : super(key: key);

  @override
  State createState() => new FullPhotoScreenState(url: url);
}

class FullPhotoScreenState extends State<FullPhotoScreen> {
  final String url;

  FullPhotoScreenState({Key key, @required this.url});

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Hero(
        tag: url,
        child: PhotoView(
          imageProvider: NetworkImage(url),
        ),
      ),
    );
  }
}