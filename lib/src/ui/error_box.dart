import 'package:flutter/material.dart';

/// A simple box with an error message
class ErrorBox extends StatelessWidget {
  /// An optional error message to show in the box.
  final String? errorMessage;
  const ErrorBox({
    Key? key,
    this.errorMessage = "Riprova più tardi",
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Qualcosa è andato storto...\n$errorMessage",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
