import 'dart:convert';

import 'package:connection_manager/connection_manager.dart';

class TestModel implements Decodable {
  final bool? test;
  final String? unescapeChars;
  TestModel({
    this.test,
    this.unescapeChars,
  });

  TestModel copyWith({
    bool? test,
    String? unescapeChars,
  }) {
    return TestModel(
      test: test ?? this.test,
      unescapeChars: unescapeChars ?? this.unescapeChars,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'test': test,
      'unescapeChars': unescapeChars,
    };
  }

  factory TestModel.fromMap(Map<String, dynamic> map) {
    return TestModel(
      test: map['test'],
      unescapeChars: map['unescapeChars'],
    );
  }

  String toJson() => json.encode(toMap());

  factory TestModel.fromJson(String source) =>
      TestModel.fromMap(json.decode(source));

  @override
  String toString() => 'TestModel(test: $test, unescapeChars: $unescapeChars)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TestModel &&
        other.test == test &&
        other.unescapeChars == unescapeChars;
  }

  @override
  int get hashCode => test.hashCode ^ unescapeChars.hashCode;
}
