import 'package:chat_app/chat_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_lists.dart';

//EMAIL STRCTURE VAR
String p = "[a-zA-Z0-9\+\.\_\%\-\+]{1,256}" +
    "\\@" +
    "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}" +
    "(" +
    "\\." +
    "[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25}" +
    ")+";
RegExp regExp = RegExp(p);

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  SharedPreferences sharedPreferences;
  bool emailPresent = true;
  bool showLoader = true;
  String emailSaved;
  Function btnFunction = null;
  TextEditingController emailController = TextEditingController();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  void initSharedPreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();

    setState(() {
      emailPresent = sharedPreferences.containsKey('email');
      showLoader = false;
      if (emailPresent) {
        emailSaved = sharedPreferences.getString('email');
      }
    });
  }

  changeBtnColor(String email) {
    if (regExp.hasMatch(email)) {
      setState(() {
        btnFunction = () async {
          await sharedPreferences.setString('email', email);
          _firebaseMessaging.subscribeToTopic(emailController.text);
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => ChatListPage(emailController.text),
            ),
          );
        };
      });
    } else {
      setState(() {
        btnFunction = null;
      });
    }
  }

  void validatorMessages() {
    if (emailController.text.isEmpty) {
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text("Please enter email!"),
        duration: Duration(milliseconds: 800),
      ));
    } else {
      if (!regExp.hasMatch(emailController.text)) {
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text("Please enter valid email!"),
          duration: Duration(milliseconds: 800),
        ));
      }
    }
  }

  void _navigateToItemDetail(
      String userEmail, String chatID, String targetEmail) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(userEmail, chatID, targetEmail),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    initSharedPreferences();

    _firebaseMessaging.subscribeToTopic('all');

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        //_showItemDialog(message);
        final notification = message['data'];
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");

        final notification = message['data'];

        _navigateToItemDetail(
            notification['to'], notification['chatID'], notification['from']);
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");

        final notification = message['data'];

        _navigateToItemDetail(
            notification['to'], notification['chatID'], notification['from']);
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(sound: true, badge: true, alert: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ListView(
          children: <Widget>[
            Image.asset(
              'images/intial_chat.jpg',
              fit: BoxFit.fitWidth,
            ),
            showLoader
                ? SpinKitPulse(
                    color: Theme.of(context).accentColor,
                    size: 70.0,
                  )
                : emailPresent
                    ? Column(
                        children: <Widget>[
                          Text(
                            'Welcome back',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 20.0,
                            ),
                          ),
                          SizedBox(
                            height: 4.0,
                          ),
                          Text(
                            '$emailSaved',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 22.0,
                            ),
                          ),
                          SizedBox(
                            height: 4.0,
                          ),
                          RaisedButton(
                            color: Theme.of(context).accentColor,
                            elevation: 10.0,
                            child: Icon(
                              Entypo.chat,
                              size: 22,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) =>
                                      ChatListPage(emailSaved),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                    : Column(
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text(
                              'Enter your email and start sending messages!',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 20.0,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(10.0),
                            child: TextFormField(
                              onChanged: (email) {
                                changeBtnColor(email);
                              },
                              controller: emailController,
                              decoration: InputDecoration(
                                hintText: 'Please enter your email',
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                  borderSide: BorderSide(),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                  fontFamily: "Poppins", fontSize: 18.0),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 30.0,
                              vertical: 10.0,
                            ),
                            child: GestureDetector(
                              onTap: () => validatorMessages(),
                              child: RaisedButton(
                                disabledColor: Colors.grey,
                                disabledElevation: 0,
                                disabledTextColor: Colors.white,
                                animationDuration: Duration(milliseconds: 500),
                                color: Theme.of(context).accentColor,
                                elevation: 10.0,
                                child: Text(
                                  'Start Chatting',
                                  style: TextStyle(fontSize: 18.0),
                                ),
                                onPressed: btnFunction,
                              ),
                            ),
                          ),
                        ],
                      ),
          ],
        ),
      ),
    );
  }
}
