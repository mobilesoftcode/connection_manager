import 'package:flutter/material.dart';

/// A simple loading spinner
class LoaderWidget extends StatelessWidget {
  const LoaderWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/loader.gif',
        height: 70,
        width: 70,
        color: Colors.black,
      ),
    );
  }
}
