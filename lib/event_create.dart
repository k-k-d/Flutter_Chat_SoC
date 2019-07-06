import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';

class CreateEvent extends StatefulWidget{
  final int _groupId;

  CreateEvent({
    Key key, @required int groupId
  }): _groupId = groupId, super(key: key);

  @override
  CreateEventState createState() {
    return new CreateEventState(groupId: _groupId);
  }
}

class CreateEventState extends State<CreateEvent> {
  final int _groupId;
  String _what;
  String _where;
  DateTime _when;
  DateTime _dateTime;
  final _key = GlobalKey<FormState>();

  CreateEventState({
    Key key, @required int groupId
  }): _groupId = groupId;

  _eventUpload() async  {
    Firestore.instance.runTransaction((transaction) async {
      await transaction.set(
        Firestore.instance.collection('groupChats').document(_groupId.toString()).collection('events').document(_when.millisecondsSinceEpoch.toString()),
        {
          'what': _what,
          'where': _where,
          'when': _when,
          'timeStamp': _when.millisecondsSinceEpoch.toString()
        });
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context)  {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: Text(
          'Create an Event',
          style: TextStyle(
            color: Colors.white,
          )
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(40.0),
        child: Form(
          key: _key,
          child: ListView(
            children: <Widget>[
              TextFormField(
                validator: (val) {
                  if(val.isEmpty) {
                    return "Fill in this Field";
                  }
                },
                onSaved: (val) {
                  _what = val;
                },
                decoration: const InputDecoration(
                  icon: Icon(Icons.event),
                  hintText: "What's the Event?",
                  labelText: 'Event',
                ),
              ),
              TextFormField(
                validator: (val) {
                  if(val.isEmpty) {
                    return "Fill in this Field";
                  }
                },
                onSaved: (val)  {
                  _where = val;
                },
                decoration: const InputDecoration(
                  icon: Icon(Icons.location_on),
                  hintText: "Where's the Event?",
                  labelText: 'Location',
                ),
              ),
              DateTimePickerFormField(
                validator: (val) {
                  if(val.toString().isEmpty) {
                    return "Fill in this Field";
                  }
                },
                onSaved: (val) {
                  _when = val;
                },
                inputType: InputType.both,
                format: DateFormat("EEEE, MMMM d, yyyy 'at' h:mma"),
                initialDate: DateTime.now(),
                editable: false,
                decoration: InputDecoration(
                  labelText: 'When?',
                  hasFloatingPlaceholder: false
                ),
                onChanged: (dt) {
                  setState(() => _dateTime = dt);
                  print('Selected date: $_dateTime');
                },
              ),
              SizedBox(height: 16.0),
              RaisedButton(
                onPressed: () {
                  debugPrint("Event Created");
                  final form = _key.currentState;
                  if(form.validate()) {
                    form.save();
                    _eventUpload();
                  }
                },
                color: Colors.blueAccent,
                textColor: Colors.white,
                child: const Text('Create Event'),
              )
            ],
          ),
        )  
      ),
    );
  }
}