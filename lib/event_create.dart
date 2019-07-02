import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';

class CreateEvent extends StatefulWidget{
  @override
  CreateEventState createState() {
    return new CreateEventState();
  }
}

class CreateEventState extends State<CreateEvent> {
  DateTime _date1;
  DateTime _date2;

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
        child: ListView(
          children: <Widget>[
            TextFormField(
              decoration: const InputDecoration(
                icon: Icon(Icons.event),
                hintText: "What's the Event?",
                labelText: 'Event *',
              ),
            ),
            TextFormField(
              decoration: const InputDecoration(
                icon: Icon(Icons.location_on),
                hintText: "Where is the party?",
                labelText: 'Location',
              ),
            ),
            DateTimePickerFormField(
              inputType: InputType.date,
              format: DateFormat("dd-MM-yyyy"),
              initialDate: DateTime.now(),
              editable: false,
              decoration: InputDecoration(
                labelText: 'Date',
                hasFloatingPlaceholder: false
              ),
              onChanged: (dt) {
                setState(() => _date1 = dt);
                print('Selected date: $_date1');
              },
            ),
            DateTimePickerFormField(
              inputType: InputType.time,
              format: DateFormat("HH:mm"),
              initialTime: TimeOfDay(hour: 0, minute: 0),
              editable: false,
              decoration: InputDecoration(
                  labelText: 'Time',
                  hasFloatingPlaceholder: false
              ),
              onChanged: (dt) {
                setState(() => _date2 = dt);
                print('Selected date: $_date2');
                print('Hour: $_date2.hour');
                print('Minute: $_date2.minute');
              },
            ),
            SizedBox(height: 16.0),
            RaisedButton(
              onPressed: () {
                debugPrint("Event Created");
              },
              color: Colors.blue,
              textColor: Colors.white,
              child: const Text('Create Event', style: TextStyle(fontSize: 20)),
            )
          ],
        ),
      ),
  );
  }
}