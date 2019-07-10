import 'package:chat_app_flutter/login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'chat.dart';
import 'group_create.dart';
import 'user_settings.dart';
import 'todo.dart';

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
  String _displayName;
  String _photoUrl;
  String _email;
  SharedPreferences _preferences;
  GoogleSignIn _googleSignIn;
  TextEditingController _controller;
  int _selectedScreen;
  int _appBarMode;
  var _appBarTitle;

  @override
  void initState()  {
    super.initState();
    _selectedScreen = 0;
    _appBarMode = 0;
    _appBarTitle = new Text('WingMate', style: TextStyle(color: Colors.white),);
    initialise();
  }

  void initialise() async {
    _preferences = await SharedPreferences.getInstance();
    _displayName = _preferences.getString('displayName');
    _photoUrl = _preferences.getString('photoUrl');
    _email = _preferences.getString('email');
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
      floatingActionButton: (_appBarMode == 0 && (_selectedScreen == 0 || _selectedScreen == 1))? FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.search, color: Colors.white,),
        onPressed: () {
          setState(() {
            _appBarMode = 1;
            _appBarTitle = new TextField(
              autofocus: true,
              onChanged: (t) {
                setState(() {
                  _controller = TextEditingController(text: t);
                });
              },
              controller: _controller,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.white,),
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.white, fontStyle: FontStyle.italic)
              ),
            );
          });
        },
      )
      :Container(),
      appBar: AppBar(
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: (_appBarMode == 0)? <Widget>[
          (_selectedScreen == 0 || _selectedScreen == 1)? IconButton(
            color: Colors.white,
            icon: Icon(Icons.group_add),
            onPressed: () {
              debugPrint("Create Group");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateGroup())
              );
              setState(() {});
            },
          )
          : Container(),
          IconButton(
            icon: Icon(Icons.settings),
            color: Colors.white,
            onPressed: () {
              debugPrint("User Settings");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen())
              );
              setState(() {
                _displayName = _preferences.getString('displayName');
                _photoUrl = _preferences.getString('photoUrl');
                _email = _preferences.getString('email');
              });
            },
          )
        ]
        : <Widget>[
          IconButton(
            icon: Icon(Icons.cancel),
            color: Colors.white,
            onPressed: () {
              setState(() {
                _controller.clear();
                _appBarMode = 0;
                _appBarTitle = new Text('WingMate', style: TextStyle(color: Colors.white),);
              });
            },
          )
        ],
        backgroundColor: Colors.blueAccent,
        title: _appBarTitle
      ),
      drawer: (_appBarMode == 0)? Drawer(
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
              currentAccountPicture: (_photoUrl != null)? CircleAvatar(backgroundImage: NetworkImage(_photoUrl)): CircleAvatar(),
              accountName: Text(_displayName??'Loading...'),
              accountEmail: Text(_email??'Loading...'),
            ),
            Card(
              elevation: 3.0,
              color: Colors.blueAccent,
              child: ListTile(
                onTap: () {},
                title: Text(
                  "Chats",
                  style: TextStyle(color: Colors.white)
                ),
                leading: Icon(Icons.chat),
              )
            ),
            Card(
              elevation: 3.0,
              child: ListTile(
                title: Text("Group Chats"),
                leading: Icon(Icons.group),
                selected: _selectedScreen == 0,
                onTap: () {_onSelect(0);},
              )
            ),
            Card(
              elevation: 3.0,
              child: ListTile(
                title: Text("Private Chats"),
                leading: Icon(Icons.person),
                selected: _selectedScreen == 1,
                onTap: () {_onSelect(1);},
              )
            ),
            Card(
              elevation: 3.0,
              color: Colors.blueAccent,
              child: ListTile(
                title: Text(
                  "ToDo List",
                  style: TextStyle(color: Colors.white)
                ),
                leading: Icon(Icons.collections_bookmark),
                selected: _selectedScreen == 2,
                onTap: () {_onSelect(2);},
              )
            ),
            Card(
              elevation: 3.0,
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
      )
      : null,
      body: (_selectedScreen == 0)? Container(
        child: StreamBuilder(
          stream: Firestore.instance.collection('groupChats').orderBy('lastActive', descending: true).snapshots(),
          builder: (context, snapshot)  {
            if(snapshot.hasData)  {
              return ListView.builder(
                padding: EdgeInsets.all(8.0),
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, i) {
                  DocumentSnapshot doc = snapshot.data.documents[i];
                  if(doc['members'].contains(_currentUserId) && (_controller == null || _controller.text.trim() == null || _controller.text.trim() == '' || doc['groupName'].toUpperCase().contains(_controller.text.toUpperCase().trim()))) {
                    return Card(
                      elevation: 3.0,
                      color: Colors.lightBlue,
                      child: ListTile(
                        title: Text(
                          doc['groupName'],
                          style: TextStyle(
                            color: Colors.white
                            // fontWeight: FontWeight.w600
                          ),
                        ),
                        leading: (doc['groupImg'] != null)? CircleAvatar(
                          backgroundImage: NetworkImage(doc['groupImg']),
                        )
                        : Container(height: 0.5, width: 0.5,),
                        onTap: () {
                          debugPrint("Tapped");
                          setState(() {
                            _controller.clear();
                            _appBarMode = 0;
                            _appBarTitle = new Text('WingMate', style: TextStyle(color: Colors.white),);
                          });
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
                  if(doc['id'] != _currentUserId && (_controller == null || _controller.text.trim() == null || _controller.text.trim() == '' || doc['displayName'].toUpperCase().contains(_controller.text.toUpperCase().trim()))) {
                    return Card(
                      elevation: 3.0,
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
                          setState(() {
                            _controller.clear();
                            _appBarMode = 0;
                            _appBarTitle = new Text('WingMate', style: TextStyle(color: Colors.white),);
                          });
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChatScreen(peerId: doc['id'], peerName: doc['displayName'], peerImg: doc['photoUrl'], type: '2pChats'))
                          );
                        },
                        leading: (doc['photoUrl'] != null)? CircleAvatar(
                          backgroundImage: NetworkImage(doc['photoUrl']),
                        )
                        : Container(height: 0.5, width: 0.5,),
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
      : (_selectedScreen == 2)? Container(
        child: TodoList(),
      )
      : Container()
    );
  }
}