import 'package:bloc_test/bloc_test.dart';
import 'package:connection_manager/connection_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      "emits [ApiCallLoadingState] and [ApiCallLoadedState] at init and when startApiCall is called with success.",
      () async {
    var future =
        ConnectionManagerStub().doApiRequest(endpoint: "mocks/test_map.json");

    final cubit = SingleApiCallCubit(apiCall: () => future);

    expect(cubit.state, ApiCallLoadingState());

    expectLater(cubit.stream, emitsInOrder([isA<ApiCallLoadedState>()]));

    await future;

    expectLater(
      cubit.stream,
      emitsInOrder([ApiCallLoadingState(), isA<ApiCallLoadedState>()]),
    );

    cubit.startApiCall();
  });

  test(
      "emits [ApiCallLoadingState] and [ApiCallErrorState] at init and when startApiCall is called with error.",
      () async {
    var future = ConnectionManagerStub(responseStatusCode: 500)
        .doApiRequest(endpoint: "mocks/test_map.json");

    final cubit = SingleApiCallCubit(apiCall: () => future);

    expect(cubit.state, ApiCallLoadingState());

    expectLater(cubit.stream, emitsInOrder([isA<ApiCallErrorState>()]));

    await future;

    expectLater(
      cubit.stream,
      emitsInOrder([ApiCallLoadingState(), isA<ApiCallErrorState>()]),
    );

    cubit.startApiCall();
  });

  blocTest<SingleApiCallCubit, SingleApiCallState>(
    'verify `response` is correct after startApiCall is called with success.',
    build: () => SingleApiCallCubit(
        apiCall:
            ConnectionManagerStub()
            .doApiRequest(endpoint: "mocks/test_map.json")),
    act: (cubit) => cubit.startApiCall(),
    verify: (cubit) async {
      var testJson = await rootBundle.loadString("mocks/test_map.json");

      expect(cubit.response?.originalResponse?.body, testJson);
    },
  );
}
