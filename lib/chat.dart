import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final String _peerId;
  final String _peerName;
  final String _peerImg;

  ChatScreen  ({
    Key key, @required String peerId, @required String peerName, @required String peerImg
  }): _peerId = peerId, _peerName = peerName, _peerImg = peerImg, super(key: key);

  @override
  State<StatefulWidget> createState() {
    return ChatScreenState(peerId: _peerId, peerName: _peerName, peerImg: _peerImg);
  }
}

class ChatScreenState extends State<ChatScreen> {
  final String _peerId;
  final String _peerName;
  final String _peerImg;
  SharedPreferences _preferences;
  String _chatId;
  String _id;
  TextEditingController _textEditingController = new TextEditingController();

  ChatScreenState ({
    Key key, @required String peerId, @required String peerName, @required String peerImg
  }): _peerId = peerId, _peerName = peerName, _peerImg = peerImg;

  @override
  void initState()  {
    super.initState();
    _chatId = '';
    _initialise();
  }

  void _initialise() async {
    _preferences = await SharedPreferences.getInstance();
    _id = _preferences.getString('id');
    if(_id.compareTo(_peerId) < 0)  {
      _chatId = '$_id-$_peerId';
    }
    else  {
      _chatId = '$_peerId-$_id';
    }
    debugPrint(_chatId);
    setState(() {
      if(_id.compareTo(_peerId) < 0)  {
        _chatId = '$_id-$_peerId';
      }
      else  {
        _chatId = '$_peerId-$_id';
      }
    });
  }
  
  void send() {
    final String msg = _textEditingController.text;
    final String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
    Firestore.instance.runTransaction((transaction) async{
      await transaction.set(
        Firestore.instance.collection('2pChats').document(_chatId).collection(_chatId).document(timeStamp),
        {
          'from': _id,
          'to': _peerId,
          'msg': msg,
          'timeStamp': timeStamp
        }
      );
    });
  }

  @override
  Widget build(BuildContext context)  {
    return Scaffold(
      backgroundColor: Colors.white24,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(
          _peerName,
          style: TextStyle(
            color: Colors.lightBlue,
            fontSize: 16.0,
          ),
        ),
        centerTitle: true,
        leading: CircleAvatar(
          backgroundImage: NetworkImage(_peerImg),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        verticalDirection: VerticalDirection.down,
        children: <Widget>[
          Flexible(
            child: StreamBuilder(
              stream: Firestore.instance.collection('2pChats').document(_chatId).collection(_chatId).orderBy('timeStamp', descending: true).limit(20).snapshots(),
              builder: (context, snapshot)  {
                if(snapshot.hasData)  {
                  return ListView.builder(
                    reverse: true,
                    itemCount: snapshot.data.documents.length,
                    padding: EdgeInsets.all(8.0),
                    itemBuilder: (context, i) {
                      DocumentSnapshot doc = snapshot.data.documents[i];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Container(
                            child: Text(
                              doc['msg'],
                              style: TextStyle(
                                color: Colors.lightBlueAccent,
                              ),
                            ),
                            padding: EdgeInsets.all(10.0),
                            width: 250,
                            margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
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
                      color: Colors.lightBlue,
                    ),
                    controller: _textEditingController,
                    decoration: InputDecoration.collapsed(
                      fillColor: Colors.black87,
                      hintText: 'Type a message',
                      hintStyle: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w100,
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
                  backgroundColor: Colors.lightBlue,
                  child: Icon(
                    Icons.send,
                    color: Colors.black87,
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