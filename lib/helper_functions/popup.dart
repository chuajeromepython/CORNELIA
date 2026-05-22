import 'package:flutter/material.dart';

void showPopUp(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(
          "Something's not right",
          style: TextStyle(color: Color.fromARGB(255, 35, 30, 38)),
        ),
        content: Text(
          message,
          style: TextStyle(color: Color.fromARGB(255, 35, 30, 38)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      );
    },
  );
}
