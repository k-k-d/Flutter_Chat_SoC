import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class GroupSettings extends StatefulWidget  {
  final String _chatId;
  
  GroupSettings({
    Key key, @required chatId
  }): _chatId = chatId, super(key: key);

  @override
  State<StatefulWidget> createState() {
    return GroupSettingsState(chatId: _chatId);
  }
}

class GroupSettingsState extends State<GroupSettings> {
  TextEditingController _controller;
  SharedPreferences _preferences;
  final int _groupId;
  String _currentUserId;
  String _groupImg;
  String _groupName;
  File _photo;
  final _key = GlobalKey<FormState>();

  GroupSettingsState({
    Key key, @required String chatId
  }): _groupId = int.parse(chatId);

  @override
  void initState() {
    super.initState();
    initialise();
  }

  initialise() async  {
    _preferences = await SharedPreferences.getInstance();
    DocumentSnapshot doc = await Firestore.instance.collection('groupChats').document(_groupId.toString()).get();
    setState(() {
      _currentUserId = _preferences.getString('id');
      _groupImg = doc['groupImg'];
      _groupName = doc['groupName'];
      _controller = TextEditingController(text: _groupName);
    });
  }

  _leaveGroup() async {
    DocumentSnapshot d1 = await Firestore.instance.collection('groupChats').document(_groupId.toString()).get();
    var members = d1['members'];
    List<dynamic> membersNew = [];
    for(var i in members) {
      if(i != _currentUserId) {
        membersNew.add(i);
      }
    }
    await Firestore.instance.collection('groupChats').document(_groupId.toString()).updateData({'members': membersNew, 'count': d1['count'] + 1});
    DocumentSnapshot d2 = await Firestore.instance.collection('users').document(_currentUserId).get();
    var groups = d2['groups'];
    List<dynamic> groupsNew = [];
    for(var j in groups)  {
      if(j != _groupId) {
        groupsNew.add(j);
      }
    }
    await Firestore.instance.collection('users').document(_currentUserId).updateData({'groups': groupsNew});
    Navigator.pop(context);
    Navigator.pop(context);
  }

  _updateName() async {
    await Firestore.instance.collection('groupChats').document(_groupId.toString()).updateData({'groupName': _groupName});
    Fluttertoast.showToast(msg: "Updated Group Name Successfully");
    Navigator.pop(context);
    Navigator.pop(context);
  }

  _uploadPhoto() async  {
    final String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
    final StorageReference storageReference = FirebaseStorage.instance.ref().child('groupChats/$_groupId/groupImg$timeStamp.png');
    final StorageUploadTask uploadTask = storageReference.putFile(_photo);
    final StorageTaskSnapshot downloadUrl = await uploadTask.onComplete;
    _groupImg = await downloadUrl.ref.getDownloadURL();
    await Firestore.instance.collection('groupChats').document(_groupId.toString()).updateData({'groupImg': _groupImg});
    setState(() {});
  }

  _camera() async {
    _photo = await ImagePicker.pickImage(
      source: ImageSource.camera
    );
    _uploadPhoto();
  }

  _gallery() async  {
    _photo = await ImagePicker.pickImage(
      source: ImageSource.gallery
    );
    _uploadPhoto();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        title: Text(
          'Group Info',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(5.0),
        child: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.fromLTRB(0.0, 7.5, 0.0, 5.0),
              child: CircularProfileAvatar(
                _groupImg??'',
                useOldImageOnUrlChange: true,
                radius: 50.0,
                backgroundColor: Colors.transparent,
                elevation: 5.0,
                foregroundColor: Colors.brown.withOpacity(0.5),
                cacheImage: true,
                onTap: () {
                  showModalBottomSheet<String>(
                    context: context,
                    builder: (BuildContext context) => Container(
                      decoration : BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.black12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          IconButton(
                            iconSize: 30.0,
                            icon: Icon(Icons.camera),
                            tooltip: 'Take a picture from camera',
                            onPressed : _camera,
                          ),
                          IconButton(
                            iconSize: 30.0,
                            icon: Icon(Icons.photo_album),
                            tooltip: 'Take a picture from gallery',
                            onPressed : _gallery,
                          ),
                        ],
                      )
                    ),
                  );
                },
              ),
            ),
            Form(
              key: _key,
              child: Row(
                children: <Widget>[
                  Flexible(
                    child: TextFormField(
                      controller: _controller,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(8.5),
                        icon: Icon(Icons.group),
                        hintText: 'Set a Group Name',
                        labelText: 'Group Name'
                      ),
                      validator: (val)  {
                        if(val.isEmpty) {
                          return 'GroupName can\'t be Empty';
                        }
                      },
                      onSaved: (String value) {
                        _groupName = value;
                      },
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.all(5.0),
                  ),
                  FlatButton(
                    color: Colors.blueAccent,
                    child: Text(
                      "Update Name",
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.white
                      ),
                    ),
                    onPressed: () {
                      debugPrint("Pressed");
                      final form = _key.currentState;
                      if(form.validate()) {
                        form.save();
                        _updateName();
                      }
                    },
                  )
                ],
              )
            ),
            // Padding(
            //   padding: EdgeInsets.symmetric(vertical: 5.0),
            // ),
            Card(
              elevation: 3.0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '     Members',
                      style: TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    color: Colors.blueGrey,
                    onPressed: () {
                      debugPrint('Pressed');
                    },
                  )
                ]
              ),
            ),
            Container(
              height: 230.0,
              child: StreamBuilder(
                stream: Firestore.instance.collection('users').snapshots(),
                builder: (context, snapshot)  {
                  if(snapshot.hasData)  {
                    return ListView.builder(
                      itemCount: snapshot.data.documents.length,
                      itemBuilder: (context, i) {
                        DocumentSnapshot doc = snapshot.data.documents[i];
                        if(doc['groups'].contains(_groupId))  {
                          return Card(
                            elevation: 3.0,
                            color: Colors.lightBlue,
                            child: ListTile(
                              title: Text(
                                doc['displayName'],
                                style: TextStyle(
                                  color: Colors.white
                                ),
                              ),
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(doc['photoUrl']),
                              ),
                            ),
                          );
                        }
                        else  {
                          return Container();
                        }
                      }
                    );
                  }
                  else  {
                    return Container();
                  }
                },
              ),
            ),
            Container(
              child: RaisedButton(
                color: Colors.red,
                padding: EdgeInsets.all(10.0),
                child: Text(
                  'Leave Group',
                  style: TextStyle(
                    color: Colors.white
                  ),
                ),
                onPressed: () {
                  debugPrint('Pressed');
                  _leaveGroup();
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}