part of 'paginated_api_call_cubit.dart';

abstract class PaginatedApiCallState extends Equatable {
  const PaginatedApiCallState();

  @override
  List<Object> get props => [];
}

class PaginatedApiCallInitial extends PaginatedApiCallState {}

class PaginatedApiCallLoading extends PaginatedApiCallState {}

class PaginatedApiCallEmpty extends PaginatedApiCallState {}

class PaginatedApiCallLoadingNewPage<T extends Decodable>
    extends PaginatedApiCallState {
  final List<T>? previousData;

  const PaginatedApiCallLoadingNewPage({required this.previousData});
}

class PaginatedApiCallSuccess<T extends Decodable>
    extends PaginatedApiCallState {
  final List<T>? data;

  const PaginatedApiCallSuccess({required this.data});
}

class PaginatedApiCallError extends PaginatedApiCallState {
  final String errorMessage;

  const PaginatedApiCallError({required this.errorMessage});

  @override
  List<Object> get props => [errorMessage];
}
