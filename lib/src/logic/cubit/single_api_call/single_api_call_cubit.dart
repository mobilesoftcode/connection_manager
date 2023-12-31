import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../connection_manager.dart';

part 'single_api_call_state.dart';

class SingleApiCallCubit<T extends Decodable, E extends Decodable>
    extends Cubit<SingleApiCallState> {
  APIRequest<T, E> apiCall;
  SingleApiCallCubit({required this.apiCall}) : super(ApiCallInitialState()) {
    startApiCall();
  }

  APIResponse<T, E>? response;

  void startApiCall({APIRequest<T, E>? newApiCall}) async {
    if (newApiCall != null) {
      apiCall = newApiCall;
    }
    emit(ApiCallLoadingState());
    var res = await apiCall();
    response = res;
    if (res.hasError) {
      emit(ApiCallErrorState(errorMessage: res.message));
    } else {
      emit(ApiCallLoadedState(response: res));
    }
  }
}
