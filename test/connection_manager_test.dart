import 'package:flutter_test/flutter_test.dart';

import 'package:connection_manager/connection_manager.dart';

void main() {
  test('', () async {
    
    var _ = ConnectionManager(
        baseUrl: "google.it",
        constantHeaders: {"Content-Type": "application/json"});
    // var res = await conn.doApiRequest(
    //     decodeErrorFromMapOverride: <Test>(statusCode, data) {
    //       return Test.fromMap(map);
    //     },
    //     requestType: ApiRequestType.get,
    //     endpoint: "/test");
  });
}
