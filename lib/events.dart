import 'package:chat_app_flutter/event_create.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventsScreen extends StatefulWidget {
  final int _groupId;

  EventsScreen({
    Key key, @required int groupId
  }): _groupId = groupId, super(key: key);

  @override
  State<StatefulWidget> createState() {
    return EventsScreenState(groupId: _groupId);
  } 
}

class EventsScreenState extends State<EventsScreen> {
  final int _groupId;
  final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final List<String> months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  EventsScreenState({
    Key key, @required int groupId
  }): _groupId = groupId;

  _removeEvent(String timeStamp) async  {
    await Firestore.instance.collection('groupChats').document(_groupId.toString()).collection('events').document(timeStamp).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        title: Text(
          'Events',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        child: StreamBuilder(
          stream: Firestore.instance.collection('groupChats').document(_groupId.toString()).collection('events').orderBy('timeStamp').snapshots(),
          builder: (context, snapshot)  {
            if(snapshot.hasData)  {
              return ListView.builder(
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, i) {
                  DocumentSnapshot doc = snapshot.data.documents[i];
                  if(int.parse(doc['timeStamp']) > DateTime.now().millisecondsSinceEpoch)  {
                    return Card(
                      elevation: 3.0,
                      color: Colors.lightBlue,
                      child: ListTile(
                        isThreeLine: true,
                        leading: Icon(Icons.event, color: Colors.white,),
                        title: Text(
                          doc['what'],
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "At ${doc['where']}\nOn ${days[doc['when'].toDate().weekday]}, ${doc['when'].toDate().day} ${months[doc['when'].toDate().month]} At ${doc['when'].toDate().hour}: ${doc['when'].toDate().minute}",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }
                  else  {
                    _removeEvent(doc['timeStamp']);
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add, color: Colors.white,),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateEvent(groupId: _groupId,))
          );
        },
      ),
    );
  }
}