import 'package:flutter/material.dart';

import 'package:scoped_model/scoped_model.dart';
import '../scoped-models/main.dart';

class ContactListPage extends StatefulWidget {
  final MainModel model;
  ContactListPage(this.model);
  @override
  State<StatefulWidget> createState() {
    return _ContactListPageState();
  }
}

class _ContactListPageState extends State<ContactListPage> {
  @override
  initState() {
    widget.model.fetchContacts(onlyForUser: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model) {
        Widget content;
        if (model.isLoading) {
          content = Center(child: CircularProgressIndicator());
        } else if (model.allContacts.length > 0) {
          content = ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              return Table(
                border: TableBorder.all(),
                columnWidths: {
                  0: FractionColumnWidth(.3),
                  1: FractionColumnWidth(.4),
                  2: FractionColumnWidth(.3)
                },
                children: [
                  TableRow(children: <Widget>[
                    ListTile(title: Text(model.allContacts[index].name)),
                    ListTile(
                        title: Text(model.allContacts[index].phone_number)),
                    ListTile(title: Text(model.allContacts[index].email))
                  ]),
                ],
              );
            },
            itemCount: model.allContacts.length,
          );
        } else {
          content = Center(child: Text('No contacts found'));
        }
        return content;
      },
    );
  }
}
