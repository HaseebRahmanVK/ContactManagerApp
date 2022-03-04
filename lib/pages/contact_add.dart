import 'package:flutter/material.dart';

import 'package:scoped_model/scoped_model.dart';

import '../widgets/helpers/ensure_visible.dart';

import '../scoped-models/main.dart';

class ContactAddPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ContactAddPageState();
  }
}

class _ContactAddPageState extends State<ContactAddPage> {
  final Map<String, dynamic> _formData = {
    'name': null,
    'phone_number': null,
    'email': null,
  };
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _titleFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _priceFocusNode = FocusNode();

  Widget _buildNameTextField() {
    return EnsureVisibleWhenFocused(
      focusNode: _titleFocusNode,
      child: TextFormField(
        focusNode: _titleFocusNode,
        decoration: InputDecoration(labelText: 'Name'),
        initialValue: '',
        validator: (String value) {
          if (value.isEmpty) {
            return 'Name can not be empty!';
          }
        },
        onSaved: (String value) {
          _formData['name'] = value;
        },
      ),
    );
  }

  Widget _buildPhoneNumberTextField() {
    return EnsureVisibleWhenFocused(
      focusNode: _descriptionFocusNode,
      child: TextFormField(
        focusNode: _descriptionFocusNode,
        maxLines: 4,
        decoration: InputDecoration(labelText: 'Phone number'),
        initialValue: '',
        validator: (String value) {
          if (value.isEmpty ||
              value.length != 10 ||
              !RegExp(r'^(?:[1-9]\d*|0)?(?:\.\d+)?$').hasMatch(value)) {
            return 'Phone number must have 10 digits and should be number';
          }
        },
        onSaved: (String value) {
          _formData['phone_number'] = value;
        },
      ),
    );
  }

  Widget _buildEmailTextField() {
    return EnsureVisibleWhenFocused(
      focusNode: _priceFocusNode,
      child: TextFormField(
        focusNode: _priceFocusNode,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: 'Email'),
        initialValue: '',
        validator: (String value) {
          if (value.isEmpty) {
            return 'Email must not be empty';
          }
        },
        onSaved: (String value) {
          _formData['email'] = value;
        },
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model) {
        return model.isLoading
            ? Center(child: CircularProgressIndicator())
            : RaisedButton(
                child: Text('Save'),
                textColor: Colors.white,
                onPressed: () => _submitForm(model.addContact),
              );
      },
    );
  }

  Widget _buildPageContent(BuildContext context) {
    final double deviceWidth = MediaQuery.of(context).size.width;
    final double targetWidth = deviceWidth > 550.0 ? 500.0 : deviceWidth * 0.95;
    final double targetPadding = deviceWidth - targetWidth;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        margin: EdgeInsets.all(10.0),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: targetPadding / 2),
            children: <Widget>[
              _buildNameTextField(),
              _buildPhoneNumberTextField(),
              _buildEmailTextField(),
              SizedBox(
                height: 10.0,
              ),
              SizedBox(
                height: 10.0,
              ),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm(Function addContact) {
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();

    addContact(
      _formData['name'],
      _formData['phone_number'],
      _formData['email'],
    ).then((bool success) {
      if (success) {
        Navigator.pushReplacementNamed(context, '/contact');
      } else {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Something went wrong'),
                content: Text('Please try again'),
                actions: <Widget>[
                  FlatButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Okay'),
                  )
                ],
              );
            });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (BuildContext context, Widget child, MainModel model) {
        final Widget pageContent = _buildPageContent(context);
        return pageContent;
      },
    );
  }
}
