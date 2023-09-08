part of 'single_api_call_cubit.dart';

abstract class SingleApiCallState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ApiCallInitialState extends SingleApiCallState {}

class ApiCallLoadingState extends SingleApiCallState {}

class ApiCallLoadedState<T, E> extends SingleApiCallState {
  final APIResponse<T, E> response;
  ApiCallLoadedState({required this.response});

  @override
  List<Object?> get props => [response];
}

class ApiCallErrorState extends SingleApiCallState {
  final String? errorMessage;
  ApiCallErrorState({this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
