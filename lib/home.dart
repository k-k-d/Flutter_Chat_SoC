import 'package:chat_app_flutter/login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'chat.dart';
import 'group_create.dart';
import 'user_settings.dart';

class HomeScreen extends StatefulWidget {
  final String _currentUserId;
  final GoogleSignIn _googleSignIn;

  HomeScreen({
    Key key, @required String currentUserId, @required GoogleSignIn googleSignIn
  }): _currentUserId = currentUserId,_googleSignIn = googleSignIn, super(key: key);
  
  @override
  State<StatefulWidget> createState() {
    return HomeScreenState(currentUserId: _currentUserId, googleSignIn: _googleSignIn);
  }
}

class HomeScreenState extends State<HomeScreen> {
  final String _currentUserId;
  SharedPreferences _preferences;
  GoogleSignIn _googleSignIn;
  int _selectedScreen;

  @override
  void initState()  {
    super.initState();
    _selectedScreen = 0;
    initialise();
  }

  void initialise() async {
    _preferences = await SharedPreferences.getInstance();
    setState(() {});
  }

  HomeScreenState({
    Key key, @required String currentUserId, @required GoogleSignIn googleSignIn
  }): _currentUserId = currentUserId, _googleSignIn = googleSignIn;

  _onSelect(int i)  {
    setState(() {
      _selectedScreen = i;
    });
    Navigator.of(context).pop();
  }
  
  @override
  Widget build(BuildContext context)  {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: <Widget>[
          IconButton(
            color: Colors.white,
            icon: Icon(Icons.group_add),
            onPressed: () {
              debugPrint("Create Group");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateGroup())
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings),
            color: Colors.white,
            onPressed: () {
              debugPrint("User Settings");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen())
              );
            },
          )
        ],
        backgroundColor: Colors.blueAccent,
        title: Text(
          'WingMate',
          style: TextStyle(
            color: Colors.white,
          )
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
              currentAccountPicture: CircleAvatar(backgroundImage: NetworkImage(_preferences.getString('photoUrl'))),
              accountName: Text(_preferences.getString('displayName')??'Loading...'),
              accountEmail: Text(_preferences.getString('email')??'Loading...'),
            ),
            Card(
              color: Colors.blueAccent,
              child: ListTile(
                title: Text(
                  "Chats",
                  style: TextStyle(color: Colors.white)
                ),
                leading: Icon(Icons.chat),
              )
            ),
            Card(
              child: ListTile(
                title: Text("Group Chats"),
                leading: Icon(Icons.group),
                selected: _selectedScreen == 0,
                onTap: () {_onSelect(0);},
              )
            ),
            Card(
              child: ListTile(
                title: Text("Private Chats"),
                leading: Icon(Icons.person),
                selected: _selectedScreen == 1,
                onTap: () {_onSelect(1);},
              )
            ),
            Card(
              color: Colors.blueAccent,
              child: ListTile(
                title: Text(
                  "ToDo List",
                  style: TextStyle(color: Colors.white)
                ),
                leading: Icon(Icons.event),
                selected: _selectedScreen == 2,
                onTap: () {_onSelect(2);},
              )
            ),
            Card(
              color: Colors.red,
              child: ListTile(
                onTap: () {
                  _googleSignIn.signOut();
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen())
                  );
                },
                title: Text(
                  "Sign Out",
                  style: TextStyle(color: Colors.white)
                ),
                leading: Icon(
                  Icons.remove_circle,
                  color: Colors.white,
                ),
              )
            ),
          ]
        ),
      ),
      body: (_selectedScreen == 0)? Container(
        child: StreamBuilder(
          stream: Firestore.instance.collection('groupChats').snapshots(),
          builder: (context, snapshot)  {
            if(snapshot.hasData)  {
              return ListView.builder(
                padding: EdgeInsets.all(8.0),
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, i) {
                  DocumentSnapshot doc = snapshot.data.documents[i];
                  if(doc['members'].contains(_currentUserId)) {
                    return Card(
                      color: Colors.lightBlue,
                      child: ListTile(
                        title: Text(
                          doc['groupName'],
                          style: TextStyle(
                            color: Colors.white
                            // fontWeight: FontWeight.w600
                          ),
                        ),
                        onTap: () {
                          debugPrint("Tapped");
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChatScreen(peerId: doc['groupId'].toString(), peerName: doc['groupName'], type: 'groupChats'))
                          );
                        },
                      ),
                    );
                  }
                  else  {
                    return Container();
                  }
                },
              );
            }
            else  {
              return Container();
            }
          },
        ),
      )
      : (_selectedScreen == 1)? Container(
        child: StreamBuilder(
          stream: Firestore.instance.collection('users').snapshots(),
          builder: (context, snapshot)  {
            if(snapshot.hasData){
              return ListView.builder(
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, i) {
                  DocumentSnapshot doc = snapshot.data.documents[i];
                  debugPrint(doc.data.toString());
                  if(doc['id'] != _currentUserId) {
                    return Card(
                      color: Colors.lightBlue,
                      child: ListTile(
                        title: Text(
                          doc['displayName']??" ",
                          style: TextStyle(
                            color: Colors.white
                          ),
                        ),
                        onTap: () {
                          debugPrint("Tapped");
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChatScreen(peerId: doc['id'], peerName: doc['displayName'], peerImg: doc['photoUrl'], type: '2pChats'))
                          );
                        },
                        leading: (doc['photoUrl'] != null)? CircleAvatar(
                          backgroundImage: NetworkImage(doc['photoUrl']),
                        )
                        : CircleAvatar(),
                        subtitle: Text(
                          doc['about']??" ",
                          style: TextStyle(
                            color: Colors.white
                          )
                        ),
                      )
                    );
                  }
                  else  {
                    return Container();
                  }
                },
                padding: EdgeInsets.all(8.0),
              );
            }
            else  {
              return Container();
            }
          },
        ),
      )
      : (_selectedScreen == 2)? Container(//Add ToDo List
      )
      : Container()
    );
  }
}