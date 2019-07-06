import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MemberAddScreen extends StatefulWidget  {
  final int _groupId;

  MemberAddScreen({
    Key key, @required groupId
  }): _groupId = groupId, super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MemberAddScreenState(groupId: _groupId);
  }
}

class MemberAddScreenState extends State<MemberAddScreen> {
  final int _groupId;
  List<bool> _v;
  List<String> _selected = [];
  int _n = 0;
  int _numberAdded = 0;

  MemberAddScreenState({
    Key key, @required groupId
  }): _groupId = groupId;

  _addMembers() async {
    if(_numberAdded > 0)  {
      for(var i in _selected) {
        DocumentSnapshot d = await Firestore.instance.collection('users').document(i).get();
        var groups = d['groups']??[];
        List<dynamic> groupsNew = [];
        for(var j in groups)  {
            groupsNew.add(j);
        }
        groupsNew.add(_groupId);
        await Firestore.instance.collection('users').document(i).updateData({'groups': groupsNew}); 
      }
      DocumentSnapshot doc = await Firestore.instance.collection('groupChats').document(_groupId.toString()).get();
      var members = doc['members'];
      List<dynamic> membersNew = [];
      for(var i in members) {
        membersNew.add(i);
      }
      for(var j in _selected) {
        membersNew.add(j);
      }
      await Firestore.instance.collection('groupChats').document(_groupId.toString()).updateData({
        'count': _numberAdded + doc['count'],
        'members': membersNew
      });
      Fluttertoast.showToast(msg: "Members Added");
      Navigator.pop(context);
    }
    else  {
      Fluttertoast.showToast(msg: "No Members Selected");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        title: Text(
          'Add Members',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Flexible(
            child: StreamBuilder(
              stream: Firestore.instance.collection('users').snapshots(),
              builder: (context, snapshot)  {
                if(snapshot.hasData)
                {
                  return ListView.builder(
                    itemCount: snapshot.data.documents.length,
                    itemBuilder: (context, i) {
                      DocumentSnapshot doc = snapshot.data.documents[i];
                      if(_n == 0) {
                        _v = [for(var i = 0; i <snapshot.data.documents.length; i++)  false];
                        _n++;
                      }
                      if(!doc['groups'].contains(_groupId))  {
                        return Card(
                          elevation: 3.0,
                          color: Colors.lightBlue,
                          child: Container(
                            child: CheckboxListTile(
                              value: _v[i],
                              onChanged: (value)  {
                                debugPrint(i.toString());
                                if(value) {
                                  _selected.insert(_numberAdded, doc['id']);
                                  _numberAdded++;
                                  debugPrint(_selected.toString());
                                }
                                else  {
                                  _selected.remove(doc['id']);
                                  _numberAdded--;
                                  debugPrint(_selected.toString());
                                }
                                setState(() {
                                  _v[i] = value;
                                  debugPrint(_v.toString());
                                });
                              },
                              title: Text(
                                doc['displayName'],
                                style: TextStyle(color: Colors.white),
                              ),
                              secondary: (doc['photoUrl'] != null)? CircleAvatar(
                                backgroundImage: NetworkImage(doc['photoUrl']),
                              )
                              : CircleAvatar(),
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
            margin: EdgeInsets.symmetric(vertical: 10.0),
            child: FloatingActionButton(
              child: Icon(Icons.add),
              mini: true,
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              onPressed: () {
                _addMembers();
              },
            ),
          )
        ],
      ),
    );
  }
}