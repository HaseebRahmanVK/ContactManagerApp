import 'package:flutter/material.dart';
import '../scoped-models/main.dart';
import '../widgets/ui_elements/logout_list_tile.dart';

import 'contact_add.dart';
import 'contact_list.dart';

class ContactsAdminPage extends StatelessWidget {
  final MainModel model;
  ContactsAdminPage(this.model);
  Widget _buildSideDrawer(BuildContext context) {
    return Drawer(
      child: Column(
        children: <Widget>[
          AppBar(
            automaticallyImplyLeading: false,
            title: Text('Choose'),
          ),
          ListTile(
            leading: Icon(Icons.shop),
            title: Text('All Contacts'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          Divider(),
          LogoutListTile()
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: _buildSideDrawer(context),
        appBar: AppBar(
          title: Text('Manage Contacts'),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(
                icon: Icon(Icons.list),
                text: 'My Contacts',
              ),
              Tab(
                icon: Icon(Icons.create),
                text: 'Add Contacts',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[ContactListPage(model), ContactAddPage()],
        ),
      ),
    );
  }
}
