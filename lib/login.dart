import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';
import 'package:firebase_core/firebase_core.dart';

class LoginScreen extends StatefulWidget
{
  @override
  State<StatefulWidget> createState() {
    return new LoginScreenState();
  }
}
    
class LoginScreenState extends State<LoginScreen>{
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  SharedPreferences _preferences;
  FirebaseUser _currentuser;
  bool _isLoggedIn;

  @override
  void initState()  {
    super.initState();
    _initialise();
  }

  void _initialise() async  {
    _preferences = await SharedPreferences.getInstance();
    _isLoggedIn = await _googleSignIn.isSignedIn();
    // if(_isLoggedIn) {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(builder: (context) => HomeScreen()));
    // }
  }

  @override
  Widget build(BuildContext context)  {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.greenAccent,
        centerTitle: true,
        title: Text(
          "Login Screen",
          style: TextStyle(
            color: Colors.white
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                  onPressed: _gSignin,
                  child: Text(
                    "Sign in with Google",
                    style: TextStyle(
                    color: Colors.white
                    ),
                  ),
                  color: Colors.blueAccent,
                  padding: EdgeInsets.all(10.0),
                ),
                RaisedButton(
                  onPressed: _gSignout,
                  child: Text(
                    "Sign out of Google",
                    style: TextStyle(
                    color: Colors.white
                    ),
                  ),
                  color: Colors.blueAccent,
                  padding: EdgeInsets.all(10.0),
                ),
              ] 
            ),
          )
        ]
      )
    );
  }

  Future<FirebaseUser> _gSignin() async {
    GoogleSignInAccount googleSignInAccount = await _googleSignIn.signIn();
    GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;
    AuthCredential authCredential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );
    FirebaseUser firebaseUser = await _auth.signInWithCredential(authCredential);
    debugPrint("Hello ${firebaseUser.displayName}");
    if(firebaseUser != null)  {
      final QuerySnapshot result = await Firestore.instance.collection('users').where('id', isEqualTo: firebaseUser.uid).getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if(documents.length == 0) {
        Firestore.instance.collection('users').document(firebaseUser.uid).setData({'displayName': firebaseUser.displayName, 'photoUrl': firebaseUser.photoUrl, 'id': firebaseUser.uid});
      }
    }
    return firebaseUser;
  }

  _gSignout() {
    _googleSignIn.signOut();
  }
}