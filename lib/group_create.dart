import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CreateGroup extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return CreateGroupState();
  }
}

class CreateGroupState extends State<CreateGroup>  {
  TextEditingController _textEditingController = new TextEditingController();
  List<bool> _v;
  List<String> _selected = [];
  SharedPreferences _preferences;
  final _key = GlobalKey<FormState>();
  String _currentUserId;
  int _n = 0;
  int _numberAdded = 0;

  @override
  void initState()  {
    super.initState();
    _currentUserId = '';
    initialise();
  }

  void initialise() async {
    _preferences = await SharedPreferences.getInstance();
    _currentUserId = _preferences.getString('id');
  }

  _makeGroup()  async{
    final String groupName = _textEditingController.text.trim();
    _selected.add(_currentUserId);
    _numberAdded++;
    final DocumentSnapshot doc = await Firestore.instance.collection('0').document('0').get();
    final int groupId = doc['number_of_groups'];
    Firestore.instance.runTransaction((transaction) async {
      await transaction.set(
        Firestore.instance.collection('groupChats').document(groupId.toString()),
        {
          'groupName':  groupName,
          'groupId':  groupId,
          'members': _selected,
          'count':  _numberAdded
        }
      );
    });
    await Firestore.instance.collection('0').document('0').updateData({'number_of_groups': groupId + 1});
    for(var i in _selected) {
      DocumentSnapshot d = await Firestore.instance.collection('users').document(i).get();
      var groups = d['groups']??[];
      List<dynamic> groupsNew = [];
      groupsNew.add(groupId);
      for(var j in groups)  {
        groupsNew.add(j);
      }
      await Firestore.instance.collection('users').document(i).updateData({'groups': groupsNew});
    }
    Fluttertoast.showToast(msg: "Group Created");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        title: Text(
          'Create Group',
          style: TextStyle(
            color: Colors.white
          ),
        ),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Container(
              margin: EdgeInsets.fromLTRB(15.0, 10.0, 20.0, 10.0),
              child: Form(key: _key, child:TextFormField(
                validator: (val)  {
                  if(val.isEmpty) {
                    return 'Group Name can\'t be left Empty';
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Set a Group Name',
                  icon: Icon(Icons.group)
                ),
                controller: _textEditingController,
              )),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
              child: Text(
                'Members',
                style: TextStyle(fontSize: 18.0),
              ),
            ),
            Flexible(
              child: StreamBuilder(
                stream: Firestore.instance.collection('users').snapshots(),
                builder: (context, snapshot)  {
                  if(snapshot.hasData)  {
                    return ListView.builder(
                      itemCount: snapshot.data.documents.length,
                      itemBuilder: (context, i) {
                        DocumentSnapshot doc = snapshot.data.documents[i];
                        if(_n == 0) { 
                          _v = [for(var i = 0; i <snapshot.data.documents.length; i++)  false];
                          _n++;
                        }
                        if(_currentUserId != doc['id'])  {
                          return Card(
                            color: Colors.lightBlue,
                            child: Container(
                              child: CheckboxListTile(
                                onChanged: (value) {
                                  if(value) {
                                    _selected.insert(_numberAdded, doc['id']);
                                    debugPrint(_selected.toString());
                                    _numberAdded++;
                                  }
                                  else  {
                                    _selected.remove(doc['id']);
                                    debugPrint(_selected.toString());
                                    _numberAdded--;
                                  }
                                  setState(() {
                                    _v[i] = value;
                                  });
                                },
                                value: _v[i],
                                secondary: (doc['photoUrl'] != null)? CircleAvatar(
                                  backgroundImage: NetworkImage(doc['photoUrl']),
                                )
                                : CircleAvatar(),
                                title: Text(
                                  doc['displayName']??'Loading...',
                                  style: TextStyle(color: Colors.white),  
                                ),
                              ),
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
              child: FloatingActionButton(
                child: Icon(Icons.add),
                mini: true,
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.black87,
                onPressed: () {
                  final form = _key.currentState;
                  if(form.validate()) {
                    _makeGroup();
                  }
                },
              ),
              margin: EdgeInsets.symmetric(vertical: 10.0),
            )
          ],
        ),
      )
    );
  }
}