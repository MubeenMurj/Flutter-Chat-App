import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:image_picker_saver/image_picker_saver.dart';
import 'photoview.dart';

//FOR STORING UNIQUE ID
String userEmail;
String chatID;

final Firestore _firestore = Firestore.instance;

final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

class ChatScreen extends StatefulWidget {
  final String userEmail, chatID, targetEmail;

  ChatScreen(this.userEmail, this.chatID, this.targetEmail);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();

  String messageText;

  String label = 'Type your message here...';

  void changeLabel() {
    Future.delayed(Duration(seconds: 1), () {
      setState(() {
        label = 'Type your message here...';
      });
    });
  }

  Future<void> sendNotification() async {
    final response = await Messaging.sendTo(
      title: 'You have a message from "${widget.userEmail}"',
      body: messageText,
      from: widget.userEmail,
      to: widget.targetEmail,
      chatID: widget.chatID,
    );

    if (response.statusCode != 200) {
      Alert(
              context: context,
              title: "Something Went Wrong",
              desc:
                  "Message was delivered Successfully but notification cannot be sent.")
          .show();
    }
  }

  int random() {
    var rng = Random();
    int a;
    for (var i = 0; i < 10; i++) {
      a = rng.nextInt(100000000);
    }
    return a;
  }

  File imageFile;
  bool isLoading;
  String imageUrl;

  //PICKING IMAGE
  Future getImage() async {
    //var image = await ImagePickerSaver.pickImage(source: ImageSource.gallery);
    imageFile = await ImagePickerSaver.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
  }

  //SENDING IMAGE
  Future uploadFile() async {
    String fileName =
        '$userEmail.${DateTime.now().millisecondsSinceEpoch.toString()}';
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, 1, 'Image');
      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("'This file is not an image'"),
        duration: Duration(milliseconds: 400),
      ));
    });
  }

  void onSendMessage(String source, int type, String content) {
    print(widget.userEmail);
    int randomNumber = random();
    _firestore
        .collection('Chats')
        .document(widget.chatID)
        .collection('messages')
        .document('${widget.chatID}.$randomNumber')
        .setData({
      'id': '${widget.chatID}.$randomNumber',
      'type': type,
      'text': content,
      'source': source,
      'sender': widget.userEmail,
      'timestamp': FieldValue.serverTimestamp(),
      'time': DateFormat().add_jm().format(DateTime.now()),
      'date': DateFormat().addPattern('MMMM dd, yyyy').format(DateTime.now()),
    });
    sendNotification();
  }

  @override
  void initState() {
    super.initState();

    userEmail = widget.userEmail;
    chatID = widget.chatID;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Instant Messaging',
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(widget.userEmail),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).accentColor,
                    width: 2.0,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      EvilIcons.image,
                      color: Theme.of(context).accentColor,
                    ),
                    onPressed: () => getImage(),
                  ),
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      controller: messageTextController,
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 10.0, horizontal: 20.0),
                        hintText: label,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      //SUBSCRIBNG TO THE MESSAGE
                      _firebaseMessaging.subscribeToTopic('all');
                      if (messageTextController.text.isNotEmpty) {
                        //CLEAR THE VALUE OF THE MESSAGE CONTROLLER
                        messageTextController.clear();
                        //STORE THE MESSAGE TO FIRESTORE
                        onSendMessage('0', 0, messageText);
                        //SEND NOTIFICATION FUNCTION
                        sendNotification();
                        //FUNCTION: SETTING THE VALUE FOR THE
                        //CLEAR THE VALUE OF THE MESSAGE TEXT VARAIBLE
                        messageText = '';
                      } else {
                        setState(() {
                          label = 'Please type something...';
                        });
                        changeLabel();
                      }
                    },
                    child: Icon(
                      FontAwesome.send_o,
                      color: Theme.of(context).accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  final String deviceId;

  MessageStream(this.deviceId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Chats')
          .document(chatID)
          .collection('messages')
          .orderBy(
            'timestamp',
            descending: false,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: SpinKitPulse(
              color: Theme.of(context).accentColor,
              size: 70.0,
            ),
          );
        }
        final messages = snapshot.data.documents.reversed;
        List<MessageBubble> messageBubbles = [];
        for (var message in messages) {
          final id = message.data['id'];
          final type = message.data['type'];
          final messageText = message.data['text'];
          final source = message.data['source'];
          final messageSender = message.data['sender'];
          final timeDate = message.data['timestamp'];
          final time = message.data['time'];
          final date = message.data['date'];

          final messageBubble = MessageBubble(
            id: id,
            type: type,
            sender: messageSender,
            text: messageText,
            source: source,
            timeDate: timeDate,
            time: time,
            date: date,
          );
          messageBubbles.add(messageBubble);
        }

        if (messageBubbles.length == 0) {
          return Expanded(
            child: Image.asset(
              'images/intial_chat.jpg',
              fit: BoxFit.fitWidth,
            ),
          );
        }

        return Expanded(
          child: ListView(
            reverse: true,
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 20.0,
            ),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatefulWidget {
  final int type;
  final String id, text, sender, source, time, date;
  final timeDate;

  MessageBubble(
      {this.id,
      this.type,
      this.sender,
      this.text,
      this.source,
      this.timeDate,
      this.time,
      this.date});

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  double dateBoxHeight = 0;

  double btnBoxHeight = 0;

  void hideDtlBtn() {
    Future.delayed(
      Duration(seconds: 3),
      () {
        setState(() {
          btnBoxHeight = 0;
        });
      },
    );
  }

  void dtlMsgCheck() {
    /* SweetAlert.show(
      context,
      subtitle: "Do you want delete this message?",
      style: SweetAlertStyle.confirm,
      showCancelButton: true,
      onPress: (bool isConfirm) {
        if (isConfirm) {
          dltMsg();
          Navigator.pop(context);
        } else {
          Navigator.pop(context);
        }
        return false;
      },
    ); */
    Alert(
      context: context,
      type: AlertType.error,
      title: "Delete",
      desc: "Do you want delete this message?",
      buttons: [
        DialogButton(
          child: Text(
            "Yes",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () {
            dltMsg();
            Navigator.pop(context);
          },
          width: 120,
        )
      ],
    ).show();
  }

  void dltMsg() {
    _firestore.collection('TableeghChat').document(widget.id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: widget.sender == userEmail
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.sender == userEmail ? 'You' : widget.sender,
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.black54,
            ),
          ),
          GestureDetector(
            onTap: () {
              widget.type == 0
                  ? setState(() {
                      dateBoxHeight = dateBoxHeight == 0 ? 14 : 0;
                    })
                  : Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => FullPhoto(
                          url: widget.source,
                        ),
                      ),
                    );
            },
            onLongPress: () {
              if (widget.sender == userEmail) {
                if (widget.id != null) {
                  setState(() {
                    btnBoxHeight = btnBoxHeight == 0 ? 20 : 0;
                  });
                  hideDtlBtn();
                }
              }
            },
            child: widget.type == 0
                ? Material(
                    elevation: 6.0,
                    borderRadius: widget.sender == userEmail
                        ? BorderRadius.only(
                            topLeft: Radius.circular(30.0),
                            bottomLeft: Radius.circular(30.0),
                            bottomRight: Radius.circular(30.0),
                          )
                        : BorderRadius.only(
                            bottomRight: Radius.circular(30.0),
                            topRight: Radius.circular(30.0),
                            bottomLeft: Radius.circular(30.0),
                          ),
                    color: widget.sender == userEmail
                        ? Theme.of(context).accentColor
                        : Colors.blueGrey,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10.0,
                        horizontal: 20.0,
                      ),
                      child: Text(
                        widget.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                  )
                : Hero(
                    tag: widget.source,
                    child: CachedNetworkImage(
                      placeholder: (context, url) => Container(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).accentColor),
                        ),
                        width: 200.0,
                        height: 200.0,
                        padding: EdgeInsets.all(70.0),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Material(
                        child: Image.asset(
                          'images/img_nf.png',
                          width: 200.0,
                          height: 200.0,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                        clipBehavior: Clip.hardEdge,
                      ),
                      imageUrl: widget.source,
                      width: 200.0,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),
          SizedBox(
            height: 4.0,
          ),
          widget.time == null
              ? SizedBox()
              : Text(
                  widget.time,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.black54,
                  ),
                ),
          widget.date == null
              ? SizedBox()
              : AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  height: dateBoxHeight,
                  child: Text(
                    widget.date,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.black54,
                    ),
                  ),
                ),
          widget.id == null
              ? SizedBox()
              : AnimatedContainer(
                  duration: Duration(milliseconds: 100),
                  height: btnBoxHeight,
                  child: FlatButton(
                    onPressed: () => dtlMsgCheck(),
                    child: Text('Unsend'),
                  ),
                ),
        ],
      ),
    );
  }
}

class Messaging {
  static final Client client = Client();

  static const String serverKey =
      'AAAAEW-rjW8:APA91bGldZxuxerQb-GUbgvhOcptAiASVge5XSNSYo9xuoikV0dnN2oamydATQ6F5D_LOGMuyxV0YdE_WBuOTz2u84-BC4SG8KRybDxl0Y8-MiX_7xPxLG14CTyW2a1_8nvB3wdVBc5F';

  static Future<Response> sendTo({
    @required String title,
    @required String body,
    @required String from,
    @required String to,
    @required String chatID,
  }) =>
      client.post(
        'https://fcm.googleapis.com/fcm/send',
        body: json.encode({
          "notification": { "title": "$title", "body": "$body"},
          "priority": "high",
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "id": "1",
            "status": "done",
            "body": "$body",
            "title": "$title",
            "from": from,
            "to": to,
            "chatID": chatID
          },
          "to": "/topics/$to"
        }),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey'
        },
      );
}
