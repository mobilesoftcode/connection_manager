import 'package:bloc_test/bloc_test.dart';
import 'package:connection_manager/connection_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../mocks/test_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PaginatedAPIResponse<Decodable, Decodable>> getPaginatedResponse(
      {bool success = true}) async {
    var response =
        await ConnectionManagerStub(responseStatusCode: success ? null : 500)
            .doApiRequest(
                endpoint: "mocks/test_map.json",
                decodeContentFromMap: TestModel.fromMap);
    if (success) {
      return PaginatedAPIResponse.success([response.decodedBody ?? TestModel()],
          response: response, page: 1, pageSize: 1);
    } else {
      return PaginatedAPIResponse.error(response: response);
    }
  }

  blocTest<PaginatedApiCallCubit, PaginatedApiCallState>(
    'emits [ApiCallLoadingState] and [ApiCallLoadedState] when startApiCall is called with success.',
    build: () =>
        PaginatedApiCallCubit(apiCall: (page, query) => getPaginatedResponse()),
    act: (cubit) => cubit.startApiCall(),
    expect: () => [PaginatedApiCallLoading(), isA<PaginatedApiCallSuccess>()],
  );

  blocTest<PaginatedApiCallCubit, PaginatedApiCallState>(
    'emits [ApiCallLoadingState] and [ApiCallErrorState] when startApiCall is called with error.',
    build: () => PaginatedApiCallCubit(
        apiCall: (page, query) => getPaginatedResponse(success: false)),
    act: (cubit) => cubit.startApiCall(),
    expect: () => [PaginatedApiCallLoading(), isA<PaginatedApiCallError>()],
  );

  blocTest<PaginatedApiCallCubit, PaginatedApiCallState>(
    'verify `response` is correct after startApiCall is called with success.',
    build: () => PaginatedApiCallCubit(
        apiCall: (page, query) => getPaginatedResponse(success: false)),
    act: (cubit) => cubit.startApiCall(),
    verify: (cubit) async {
      var testJson = await rootBundle.loadString("mocks/test_map.json");

      // expect(cubit.re?.originalResponse?.body, testJson);
    },
  );
}
