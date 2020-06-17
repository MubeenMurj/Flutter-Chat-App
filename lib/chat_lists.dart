import 'dart:math';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'chat_screen.dart';

final Firestore _firestore = Firestore.instance;
String userEmail;

class ChatListPage extends StatefulWidget {
  final String userEmail;

  ChatListPage(this.userEmail);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  /* void messagesStream() async {
    await for (var snapshot in _firestore.collection('messages').snapshots()) {
      for (var message in snapshot.documents) {
        print(message.data);
      }
    }
  } */
  int random() {
    var rng = Random();
    int a;
    for (var i = 0; i < 10; i++) {
      a = rng.nextInt(100000000);
    }
    return a;
  }

  TextEditingController targetEmail = TextEditingController();
  bool showLoader = false;

  @override
  void initState() {
    super.initState();
    userEmail = widget.userEmail;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Messages List'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add_circle_outline),
            onPressed: () {
              Alert(
                  context: context,
                  title: "New Chat",
                  content: Column(
                    children: <Widget>[
                      TextField(
                        controller: targetEmail,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          icon: Icon(Icons.account_circle),
                          labelText: 'Enter Email!',
                        ),
                      ),
                    ],
                  ),
                  buttons: [
                    DialogButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        setState(() {
                          showLoader = true;
                        });
                        bool chatAlreadyPresent = false;
                        String presentChatID;
                        //  CHECKING IF CHAT IS ALREADY PRESENT
                        await for (var snapshot
                            in _firestore.collection('Users').snapshots()) {
                          print(
                              'into parent loop ----------------------------------');
                          for (var singleChat in snapshot.documents) {
                            print(singleChat.data['email']);
                            /* if (singleChat.data['chat_with'] ==
                                targetEmail.text) {
                              chatAlreadyPresent = true;
                              presentChatID = singleChat.data['chat_id'];
                              print('into if ---------------------------------');
                              break;
                            } */
                          }
                        }
                        print(
                            'after loop ----------------------------------------');
                        if (chatAlreadyPresent) {
                          setState(() {
                            showLoader = false;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(widget.userEmail,
                                  presentChatID, targetEmail.text),
                            ),
                          );
                        } else {
                          int randomNumber = random();
                          // setting signed in user document and email in it
                          await _firestore
                              .collection('Users')
                              .document(widget.userEmail)
                              .setData({
                            'email': widget.userEmail,
                          });
                          // placing chat id id in signin user
                          await _firestore
                              .collection('Users')
                              .document(widget.userEmail)
                              .collection('chats')
                              .document(
                                  '${widget.userEmail}-$randomNumber-${targetEmail.text}')
                              .setData({
                            'chat_id':
                                '${widget.userEmail}-$randomNumber-${targetEmail.text}',
                            'chat_with': targetEmail.text,
                          });
                          // creating chat in chats collection
                          await _firestore
                              .collection('Chats')
                              .document(
                                  '${widget.userEmail}-$randomNumber-${targetEmail.text}')
                              .setData({
                            'id':
                                '${widget.userEmail}-$randomNumber-${targetEmail.text}',
                          });
                          // storing members in chat
                          await _firestore
                              .collection('Chats')
                              .document(
                                  '${widget.userEmail}-$randomNumber-${targetEmail.text}')
                              .collection('members')
                              .add({
                            '1': widget.userEmail,
                            '2': targetEmail.text,
                          });
                          // setting target user document and email in it
                          await _firestore
                              .collection('Users')
                              .document(targetEmail.text)
                              .setData({
                            'email': targetEmail.text,
                          });
                          // placing chat id id in target user
                          await _firestore
                              .collection('Users')
                              .document(targetEmail.text)
                              .collection('chats')
                              .document(
                                  '${widget.userEmail}-$randomNumber-${targetEmail.text}')
                              .setData({
                            'chat_id':
                                '${widget.userEmail}-$randomNumber-${targetEmail.text}',
                            'chat_with': widget.userEmail,
                          });
                          setState(() {
                            showLoader = false;
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                  widget.userEmail,
                                  '${widget.userEmail}-$randomNumber-${targetEmail.text}',
                                  targetEmail.text),
                            ),
                          );
                        }
                      },
                      child: Text(
                        "Chat",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ]).show();
            },
          ),
        ],
      ),
      body: ModalProgressHUD(child: MessageStream(), inAsyncCall: showLoader),
    );
  }
}

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Users')
          .document(userEmail)
          .collection('chats')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Center(
              child: SpinKitPulse(
                color: Theme.of(context).accentColor,
                size: 70.0,
              ),
            ),
          );
        }
        final messages = snapshot.data.documents.reversed;
        List<SingleList> messageBubbles = [];
        for (var message in messages) {
          final id = message.data['chat_id'];
          final name = message.data['chat_with'];

          final messageBubble = SingleList(
            code: id,
            targetEmail: name,
          );
          messageBubbles.add(messageBubble);
        }

        if (messageBubbles.length == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset('images/no_message.jpg'),
              Text(
                'No Messages Yet!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF91A5C3),
                  fontSize: 30.0,
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 10.0,
            vertical: 20.0,
          ),
          children: messageBubbles,
        );
      },
    );
  }
}

class SingleList extends StatefulWidget {
  final String code, targetEmail;

  SingleList({@required this.code, @required this.targetEmail});

  @override
  _SingleListState createState() => _SingleListState();
}

class _SingleListState extends State<SingleList> {
  final TextEditingController message = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print(userEmail);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(userEmail, widget.code, widget.targetEmail),
          ),
        );
      },
      child: ListTile(
        leading: Icon(Icons.message),
        title: Text(widget.targetEmail),
        trailing: Icon(Icons.arrow_forward),
      ),
    );
  }
}

class DeleteDialog extends StatefulWidget {
  final String code;

  DeleteDialog(this.code);

  @override
  _DeleteDialogState createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<DeleteDialog> {
  double containerHeight = 0;

  void changeHeight() {
    setState(() {
      containerHeight = 16;
    });
    hideText();
  }

  void hideText() {
    Future.delayed(
      Duration(seconds: 1),
      () {
        setState(() {
          containerHeight = 0;
        });
      },
    );
  }

  int selectedRadio;

  setSelectedRadio(int value) {
    setState(() {
      selectedRadio = value;
    });
  }

  void deleteChat() {
    _firestore.collection('messages').document(widget.code).delete();
  }

  void deleteAllMessages() async {
    _firestore
        .collection('messages')
        .document(widget.code)
        .collection(widget.code)
        .getDocuments()
        .then((snapshot) {
      for (DocumentSnapshot ds in snapshot.documents) {
        ds.reference.delete();
      }
    });

    _firestore.collection('messages').document(widget.code).delete();
  }

  @override
  void initState() {
    super.initState();
    selectedRadio = 0;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      children: <Widget>[
        Text(
          'Delete',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 20.0,
          ),
        ),
        ListTile(
          title: Text('Delete this chat from here only?'),
          leading: Radio(
            value: 1,
            groupValue: selectedRadio,
            activeColor: Theme.of(context).accentColor,
            onChanged: (value) {
              setSelectedRadio(value);
            },
          ),
        ),
        ListTile(
          title: Text('Delete this chat from everywhere?'),
          leading: Radio(
            value: 2,
            groupValue: selectedRadio,
            activeColor: Theme.of(context).accentColor,
            onChanged: (value) {
              setSelectedRadio(value);
            },
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20.0),
          child: RaisedButton(
            child: Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.0,
              ),
            ),
            color: Color(0xFFCC3300),
            onPressed: () {
              switch (selectedRadio) {
                case 1:
                  deleteChat();
                  Navigator.pop(context);
                  break;
                case 2:
                  deleteAllMessages();
                  Navigator.pop(context);
                  break;
                default:
                  changeHeight();
              }
            },
          ),
        ),
        AnimatedContainer(
          margin: EdgeInsets.only(top: 10.0),
          duration: Duration(milliseconds: 100),
          height: containerHeight,
          child: Text(
            'Please select any option!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.0,
            ),
          ),
        ),
      ],
    );
  }
}
