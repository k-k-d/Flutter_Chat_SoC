import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'chat.dart';
import 'create.dart';

class HomeScreen extends StatefulWidget {
  final String _currentUserId;

  HomeScreen({
    Key key, @required String currentUserId
  }): _currentUserId = currentUserId, super(key: key);
  
  @override
  State<StatefulWidget> createState() {
    return HomeScreenState(currentUserId: _currentUserId);
  }
}

class HomeScreenState extends State<HomeScreen> {
  final String _currentUserId;
  int _groups;
  
  HomeScreenState({
    Key key, @required String currentUserId
  }): _currentUserId = currentUserId;
  
  @override
  void initState() {
    super.initState();
    initialise();
  }

  initialise() async  {
    DocumentSnapshot doc = await Firestore.instance.collection('users').document(_currentUserId).get();
    _groups = doc['groups'].length;
  }
  
  @override
  Widget build(BuildContext context)  {
    return Scaffold(
      backgroundColor: Colors.white24,
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.lightBlue),
        actions: <Widget>[
          IconButton(
            color: Colors.lightBlue,
            icon: Icon(Icons.group_add),
            onPressed: () {
              debugPrint("Create Group");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateGroup())
              );  
            },            //  Add Group Creation here
          ),
          IconButton(
            icon: Icon(Icons.settings),
            color: Colors.lightBlue,
            onPressed: () {debugPrint("User Settings");},            //  Add User Options here
          )
        ],
        backgroundColor: Colors.black87,
        centerTitle: true,
        title: Text(
          'Home',
          style: TextStyle(
            color: Colors.lightBlue,
          )
        ),
      ),
      body: Stack(
        children: <Widget>[
          Container(
            child: StreamBuilder(
              stream: Firestore.instance.collection('groupChats').snapshots(),
              builder: (context, snapshot)  {
                if(snapshot.hasData)  {
                  return ListView.builder(
                    itemCount: _groups,
                    itemBuilder: (context, i) {
                      DocumentSnapshot doc = snapshot.data.documents[i];
                      if(doc['members'].contains(_currentUserId)) {
                        return Card(
                          color: Colors.black87,
                          child: ListTile(
                            title: Text(
                              doc['groupName'],
                              style: TextStyle(
                                color: Colors.lightBlue
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
          ),
          Container(
            margin: EdgeInsets.all(30.0),
            child: StreamBuilder(
              stream: Firestore.instance.collection('users').snapshots(),
              builder: (context, snapshot)  {
                if(snapshot.hasData){
                  return ListView.builder(
                    itemCount: snapshot.data.documents.length,
                    itemBuilder: (context, i) {
                      DocumentSnapshot doc = snapshot.data.documents[i];
                      if(doc['id'] != _currentUserId) {
                        return Card(
                          color: Colors.black87,
                          child: ListTile(
                            title: Text(
                              doc['displayName'],
                              style: TextStyle(
                                color: Colors.lightBlue),
                            ),
                            onTap: () {
                              debugPrint("Tapped");
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ChatScreen(peerId: doc['id'], peerName: doc['displayName'], peerImg: doc['photoUrl'], type: '2pChats'))
                              );
                            },
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(doc['photoUrl']),
                            ),
                            subtitle: Text(
                              doc['about']??'NA',
                              style: TextStyle(
                                color: Colors.lightBlue
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
          ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.end,
          //   children: <Widget>[FloatingActionButton(
          //     onPressed: null,
          //     backgroundColor: Colors.lightBlue,
          //     child: Icon(Icons.group_add),
          //   )]
          // )
        ],
      ),
    );
  }
}