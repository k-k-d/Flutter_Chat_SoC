import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'group_settings.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_saver/image_saver.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  final String _peerId;
  final String _peerName;
  final String _peerImg;
  final String _type;

  ChatScreen  ({
    Key key, @required String peerId, @required String peerName, String peerImg, @required String type
  }): _peerId = peerId, _peerName = peerName, _peerImg = peerImg, _type = type, super(key: key);

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
  
  void _sendText() {
    final String msg = _textEditingController.text;
    final String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
    if(msg.isNotEmpty)  {
      Firestore.instance.runTransaction((transaction) async{
        await transaction.set(
          Firestore.instance.collection(_type).document(_chatId).collection('messages').document(timeStamp),
          {
            'type': 0,
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

  void _sendImg(int i) async{
    File pic;
    if(i == 0)  {
      pic = await ImagePicker.pickImage(source: ImageSource.gallery);
    }
    else if(i == 1) {
      pic = await ImagePicker.pickImage(source: ImageSource.camera);
    }
    final String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
    final StorageReference storageReference = FirebaseStorage.instance.ref().child('$_type/$_chatId/messages/$timeStamp.png');
    final StorageUploadTask uploadTask = storageReference.putFile(pic);
    final StorageTaskSnapshot downloadUrl = await uploadTask.onComplete;
    final String msg = await downloadUrl.ref.getDownloadURL();
    Firestore.instance.runTransaction((transaction) async {
      await transaction.set(
        Firestore.instance.collection(_type).document(_chatId).collection('messages').document(timeStamp),
        {
          'type': 1,
          'from': _id,
          'to': _peerId,
          'msg': msg,
          'timeStamp': timeStamp,
          'fromImg': _img
        }
      );
    });
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
                MaterialPageRoute(builder: (context) => GroupSettings(chatId: _chatId))
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
        // leading: _peerImg != null? CircleAvatar(
        //   backgroundImage: NetworkImage(_peerImg),
        // ): Container(),
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
                          (doc['type'] == 0)? Card(
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
                          )
                          : (doc['type'] == 1)? Card(
                            color: (doc['from'] == _id)? Colors.lightBlueAccent: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(20.0),)
                            ),
                            child: Container(
                              child: InkWell(
                                child: FadeInImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(doc['msg']),
                                  placeholder: (AssetImage('assets/placeholder.png')),
                                ),
                                onTap: () async{
                                  debugPrint("Tapped");
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context)  {
                                      return Container(
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlue),
                                          ),
                                        ),
                                      );
                                    })
                                  );
                                  var response = await http.get(doc['msg']);
                                  File file = await ImageSaver.toFile(fileData: response.bodyBytes);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context)  {
                                      return Container(
                                        child: PhotoView(
                                          imageProvider: NetworkImage(doc['msg']),
                                        ),
                                      );
                                    })
                                  );
                                },
                              ),
                              padding: EdgeInsets.all(10.0),
                              width: 250,
                              margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                              decoration: BoxDecoration(
                                color: (doc['from'] == _id)? Colors.lightBlueAccent: Colors.white,
                              ),
                            ),
                          )
                          : Container(),
                          (doc['from'] == _id)? CircleAvatar(
                            radius: 15.0,
                            backgroundImage:  NetworkImage(_img),
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
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
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
                IconButton(
                  icon: Icon(Icons.photo),
                  onPressed: () {
                    debugPrint('Pressed');
                    _sendImg(0);
                  },
                  iconSize: 30.0,
                ),
                IconButton(
                  icon: Icon(Icons.camera_enhance),
                  iconSize: 30.0,
                  onPressed: () {
                    debugPrint('Pressed');
                    _sendImg(1);
                  },
                ),
                FloatingActionButton(
                  onPressed: () {
                    debugPrint('Pressed');
                    _sendText();
                  },                 
                  backgroundColor: Colors.blueAccent,
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                )
              ],
            ),
            margin: EdgeInsets.all(7.5),
          )
        ],
      ),
    );
  }
}