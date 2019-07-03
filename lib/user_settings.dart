import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return SettingsScreenState();
  }
}

class SettingsScreenState extends State<SettingsScreen> {
  String _displayName;
  String _about;
  String _currentUserId;
  String _photoUrl;
  TextEditingController _controller1;
  TextEditingController _controller2;
  final _key = GlobalKey<FormState>();
  File _photo;
  String photoUrl;
  SharedPreferences _preferences;

  _uploadPhoto() async  {
    final StorageReference storageReference = FirebaseStorage.instance.ref().child('users/$_currentUserId/profilePic.png');
    final StorageUploadTask uploadTask = storageReference.putFile(_photo);
    final StorageTaskSnapshot downloadUrl = await uploadTask.onComplete;
    photoUrl = await downloadUrl.ref.getDownloadURL();
    Firestore.instance.collection('users').document(_currentUserId).updateData({'photoUrl': photoUrl});
    _preferences.setString('photoUrl', photoUrl);
    setState(() {_photoUrl = photoUrl;});
  }

  _updateInfo() async {
    Firestore.instance.collection('users').document(_currentUserId).updateData({'displayName': _displayName, 'about': _about, 'photoUrl': photoUrl});
    _preferences.setString('displayName', _displayName);
    _preferences.setString('about', _about);
    _preferences.setString('photoUrl', photoUrl);
    Fluttertoast.showToast(msg: "Updated Info Successfully");
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    initialise();
  }

  initialise() async  {
    _preferences = await SharedPreferences.getInstance();
    setState(() {
      _about = _preferences.getString('about');
      _displayName = _preferences.getString('displayName');
      _currentUserId = _preferences.getString('id');
      _photoUrl = _preferences.getString('photoUrl');
      _controller1 = TextEditingController(text: _displayName);
      _controller2 = TextEditingController(text: _about);
    });
  }

  _camera() async {
    _photo = await ImagePicker.pickImage(
      source: ImageSource.camera
    );
    _uploadPhoto();
  }

  _gallery() async {
    _photo = await ImagePicker.pickImage(
      source: ImageSource.gallery
    );
    _uploadPhoto();
  }

  @override
  Widget build(BuildContext context)  {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        title: Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
          )
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(40.0),
        child: Form(
          key: _key,
          child: Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(bottom: 10.0), 
                child: CircularProfileAvatar(
                  _photoUrl?? '',
                  radius: 100.0,
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
                          children: <Widget>[
                            IconButton(
                              iconSize:20.0,
                              icon: Icon(Icons.camera),
                              tooltip: 'Take a picture from camera',
                              onPressed : _camera,
                            ),
                            IconButton(
                              iconSize:20.0,
                              icon: Icon(Icons.photo_album),
                              tooltip: 'Take a picture from gallery',
                              onPressed : _gallery,
                            ),
                          ],
                        )
                      ),
                    );
                  },
                )
              ),
              TextFormField(
                validator: (val)  {
                  if(val.isEmpty) {
                    return "Display Name can't be Empty";
                  }
                },
                controller: _controller1,
                decoration: const InputDecoration(
                  icon: Icon(Icons.person_pin),
                  hintText: "Set your Display Name",
                  labelText: 'Display Name',
                ),
                onSaved: (String value) {
                  _displayName = value;
                }
              ),
              TextFormField(
                controller: _controller2,
                decoration: const InputDecoration(
                  icon: Icon(Icons.location_on),
                  hintText: "Set your Description",
                  labelText: 'Description',
                ),
                onSaved: (String value){
                  _about = value??'-';
                }
              ),
              Container(
                margin: EdgeInsets.only(top: 30.0),
                height: 40.0,
                child: RaisedButton(
                  onPressed: () {
                    debugPrint('Updating Profile');
                    final form = _key.currentState;
                    if(form.validate()) {
                      form.save();
                      _updateInfo();
                    }
                  },
                  child: Text(
                    'Update Profile',
                    style: TextStyle(color: Colors.white),
                  ),
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
        )
      ),
    );
  }
}