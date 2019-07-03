import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodoList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return TodoListState();
  }
}

class TodoListState extends State<TodoList> {
  List<String> _todoItems = [];
  SharedPreferences prefs;

  @override
  void initState()  {
    super.initState();
    _loadTodoList();
  }

  _loadTodoList() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _todoItems = (prefs.getStringList('_todoItems') ?? []);
    });
  }

  void _addTodoItem(String task) {
    if(task.length > 0) {
      setState(() {
        _todoItems.add(task);
        prefs.setStringList('_todoItems', _todoItems);
      });
    }
  }

  void _removeTodoItem(int index) {
    setState(() {
      _todoItems.removeAt(index);
      prefs.setStringList('_todoItems', _todoItems);
    });
  }

  void _promptRemoveTodoItem(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: Text('Mark "${_todoItems[index]}" as done?'),
          actions: <Widget>[
            new FlatButton(
              child: Text('CANCEL'),
              onPressed: () => Navigator.of(context).pop()
            ),
            new FlatButton(
              child: new Text('MARK AS DONE'),
              onPressed: () {
                _removeTodoItem(index);
                Navigator.of(context).pop();
              }
            )
          ]
        );
      }
    );
  }

  Widget _buildTodoList() {
    return new ListView.builder(
      itemBuilder: (context, index) {
        if(index < _todoItems.length) {
          return _buildTodoItem(_todoItems[index], index);
        }
      },
    );
  }

  Widget _buildTodoItem(String todoText, int index) {
    return Card(
      color: (index%2 == 0) ? Colors.blue : Colors.purpleAccent,
      child: ListTile(
        title: Text(todoText, style: TextStyle(color: Colors.white)),
        leading: Icon(Icons.bookmark),
        onLongPress: () => _promptRemoveTodoItem(index),
      )
    );
  }

  void _pushAddTodoScreen() {
    Navigator.of(context).push(
      new MaterialPageRoute(
        builder: (context) {
          return new Scaffold(
            backgroundColor: Colors.white,
            appBar: new AppBar(
              backgroundColor: Colors.blueAccent,
              title: new Text('Add a new task', style: TextStyle(color: Colors.white))
            ),
            body: new TextField(
              autofocus: true,
              onSubmitted: (val) {
                _addTodoItem(val);
                Navigator.pop(context); 
              },
              decoration: new InputDecoration(
                hintText: 'Enter something to do...',
                contentPadding: const EdgeInsets.all(16.0)
              ),
            )
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        _buildTodoList(),
        new Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Container(
              margin: EdgeInsets.symmetric(vertical: 10.0),
              child: Center(
                child: new FloatingActionButton(
                  onPressed: _pushAddTodoScreen,
                  tooltip: 'Add task',
                  backgroundColor: Colors.blueAccent,
                  child: new Icon(Icons.add)
                ),
              )
            )
          ]
        )
      ]
    );
  }
}