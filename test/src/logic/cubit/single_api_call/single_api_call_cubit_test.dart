import 'package:bloc_test/bloc_test.dart';
import 'package:connection_manager/connection_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  blocTest<SingleApiCallCubit, SingleApiCallState>(
    'emits [ApiCallLoadingState] and [ApiCallLoadedState] when startApiCall is called with success.',
    build: () => SingleApiCallCubit(
        apiCall: () =>
            ConnectionManagerStub().doApiRequest(endpoint: "mocks/test.json")),
    act: (cubit) => cubit.startApiCall(),
    expect: () => [ApiCallLoadingState(), isA<ApiCallLoadedState>()],
  );

  blocTest<SingleApiCallCubit, SingleApiCallState>(
    'emits [ApiCallLoadingState] and [ApiCallErrorState] when startApiCall is called with error.',
    build: () => SingleApiCallCubit(
        apiCall: () => ConnectionManagerStub(responseStatusCode: 500)
            .doApiRequest(endpoint: "mocks/test.json")),
    act: (cubit) => cubit.startApiCall(),
    expect: () => [ApiCallLoadingState(), isA<ApiCallErrorState>()],
  );

  blocTest<SingleApiCallCubit, SingleApiCallState>(
    'verify `response` is correct after startApiCall is called with success.',
    build: () => SingleApiCallCubit(
        apiCall: () =>
            ConnectionManagerStub().doApiRequest(endpoint: "mocks/test.json")),
    act: (cubit) => cubit.startApiCall(),
    verify: (cubit) async {
      var testJson = await rootBundle.loadString("mocks/test.json");

      expect(cubit.response?.originalResponse?.body, testJson);
    },
  );
}
