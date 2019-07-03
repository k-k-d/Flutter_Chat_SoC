import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'group_settings.dart';

class ChatScreen extends StatefulWidget {
  final String _peerId;
  final String _peerName;
  final String _peerImg;
  final String _type;

  ChatScreen  ({
    Key key, @required String peerId, @required String peerName, String peerImg, @required String type
  }): _peerId = peerId, _peerName = peerName, _peerImg = peerImg, _type = type,super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ChatScreenState(peerId: _peerId, peerName: _peerName, peerImg: _peerImg, type: _type);
  }
}

class ChatScreenState extends State<ChatScreen> {
  final String _peerId;
  final String _peerName;
  final String _peerImg;
  final String _type;
  SharedPreferences _preferences;
  String _chatId;
  String _id;
  String _img;
  TextEditingController _textEditingController = new TextEditingController();

  ChatScreenState ({
    Key key, @required String peerId, @required String peerName, String peerImg, @required String type
  }): _peerId = peerId, _peerName = peerName, _peerImg = peerImg, _type = type;

  @override
  void initState()  {
    super.initState();
    _chatId = '';
    _initialise();
  }

  void _initialise() async {
    _preferences = await SharedPreferences.getInstance();
    _id = _preferences.getString('id');
    _img = _preferences.getString('photoUrl');
    switch(_type)
    {
      case '2pChats':
        if(_id.compareTo(_peerId) < 0)  {
          _chatId = '$_id-$_peerId';
        }
        else  {
          _chatId = '$_peerId-$_id';
        }
        debugPrint(_chatId);
        break;
      case 'groupChats':
        _chatId = _peerId;
    }
    setState(() {});
  }
  
  void send() {
    final String msg = _textEditingController.text;
    final String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
    if(msg.isNotEmpty)  {
      Firestore.instance.runTransaction((transaction) async{
        await transaction.set(
          Firestore.instance.collection(_type).document(_chatId).collection('messages').document(timeStamp),
          {
            'from': _id,
            'to': _peerId,
            'msg': msg,
            'timeStamp': timeStamp,
            'fromImg': _img
          }
        );
      });
    }
    _textEditingController.clear();
  }

  @override
  Widget build(BuildContext context)  {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        actions: <Widget>[
          (_type == 'groupChats')? IconButton(
            color: Colors.white,
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GroupSettings())
              );
            },
          )
          : Container()
        ],
        backgroundColor: Colors.blueAccent,
        title: Text(
          _peerName,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: _peerImg != null? CircleAvatar(
          backgroundImage: NetworkImage(_peerImg),
        ): Container(),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        verticalDirection: VerticalDirection.down,
        children: <Widget>[
          Flexible(
            child: StreamBuilder(
              stream: Firestore.instance.collection(_type).document(_chatId).collection('messages').orderBy('timeStamp', descending: true).limit(20).snapshots(),
              builder: (context, snapshot)  {
                if(snapshot.hasData)  {
                  return ListView.builder(
                    reverse: true,
                    itemCount: snapshot.data.documents.length,
                    padding: EdgeInsets.all(8.0),
                    itemBuilder: (context, i) {
                      DocumentSnapshot doc = snapshot.data.documents[i];
                      return Row(
                        mainAxisAlignment: (doc['from'] == _id)? MainAxisAlignment.end: MainAxisAlignment.start,
                        children: <Widget>[
                          (doc['from'] != _id)? CircleAvatar(
                            radius: 15.0,
                            backgroundImage: NetworkImage(doc['fromImg']),
                          )
                          : Container(),
                          Card(
                            color: (doc['from'] == _id)? Colors.lightBlueAccent: Colors.grey.shade500,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(20.0),)
                            ),
                            child: Container(
                              child: Text(
                                doc['msg'],
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              padding: EdgeInsets.all(10.0),
                              width: 250,
                              margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                              decoration: BoxDecoration(
                                color: (doc['from'] == _id)? Colors.lightBlueAccent: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          (doc['from'] == _id)? CircleAvatar(
                            radius: 15.0,
                            backgroundImage:  NetworkImage(doc['fromImg']),
                          )
                          : Container(),
                        ],
                      );
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
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.black87
                )
              )
            ),
            child: Row(
              children: <Widget>[
                Flexible(
                  child: TextField(
                    style: TextStyle(
                      color: Colors.black87,
                    ),
                    controller: _textEditingController,
                    decoration: InputDecoration.collapsed(
                      hintText: 'Type a message',
                      hintStyle: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w400,
                        color: Colors.blueGrey
                      ),
                    ),
                  ),
                ),
                FloatingActionButton(
                  onPressed: () {
                    debugPrint('Pressed');
                    send();
                  },                 
                  backgroundColor: Colors.blueAccent,
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                )
              ],
              // mainAxisAlignment: MainAxisAlignment.end,
              // verticalDirection: VerticalDirection.down,
            ),
            margin: EdgeInsets.all(7.5),
          )
        ],
      ),
    );
  }
}