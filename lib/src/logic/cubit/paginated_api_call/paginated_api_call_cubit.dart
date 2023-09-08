import '../../../../connection_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'paginated_api_call_state.dart';

class PaginatedApiCallCubit<T extends Decodable, E extends Decodable>
    extends Cubit<PaginatedApiCallState> {
  PaginatedAPIRequest<T, E> apiCall;

  /// The initial page for pagination. Usually pagination starts from 0 (default value),
  /// but a different number can be specified to be used as first page.
  final int initialPage;
  PaginatedApiCallCubit(
      {required this.apiCall, Map<String, String>? query, this.initialPage = 0})
      : super(PaginatedApiCallInitial()) {
    _query = query;
  }

  PaginatedAPIResponse<T, E>? _paginatedApiResponse;
  PaginatedAPIResponse<T, E>? get paginatedApiResponse => _paginatedApiResponse;

  Map<String, String>? _query;

  /// You can either specify a page, or go back/forward from actual page leaving calculations to the package.
  /// If you do not provide `newPage` than the next page is taken by default if `goToPreviousPage` is not _true_.
  /// Old data will be completely wiped and replaced.
  void startApiCallAndReplaceData(
      {bool goToPreviousPage = false,
      int? newPage,
      Map<String, String>? query}) async {
    if (query != null) _query = query;
    var page = newPage ?? initialPage;
    if (_paginatedApiResponse?.page != null) {
      page = (_paginatedApiResponse?.page ?? (initialPage - 1)) +
          (goToPreviousPage ? (initialPage - 1) : 1);
    }

    emit(PaginatedApiCallLoading());
    _paginatedApiResponse = null;
    var response = await apiCall(page, _query);
    if (isClosed) {
      return;
    }

    if (response.hasError) {
      emit(PaginatedApiCallError(
          errorMessage: response.message ?? "Errore generico"));
      return;
    }
    _paginatedApiResponse = response;
    if (_paginatedApiResponse?.data?.isEmpty ?? true) {
      emit(PaginatedApiCallEmpty());
      return;
    }
    emit(PaginatedApiCallSuccess<T>(data: _paginatedApiResponse?.data ?? []));
  }

  void startApiCall({Map<String, String>? query}) async {
    if (query != null) _query = query;
    var page = (_paginatedApiResponse?.page ?? (initialPage - 1)) + 1;

    if (page == initialPage) {
      emit(PaginatedApiCallLoading());
    } else {
      emit(PaginatedApiCallLoadingNewPage(
          previousData: _paginatedApiResponse?.data));
    }

    var response = await apiCall(page, _query);
    if (isClosed) {
      return;
    }

    if (response.hasError) {
      emit(PaginatedApiCallError(
          errorMessage: response.message ?? "Errore generico"));
      return;
    }
    if (_paginatedApiResponse == null) {
      _paginatedApiResponse = response;
    } else {
      _paginatedApiResponse?.page += 1;
      _paginatedApiResponse?.data?.addAll(response.data ?? []);
    }
    if (_paginatedApiResponse?.data?.isEmpty ?? true) {
      emit(PaginatedApiCallEmpty());
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback(
      (timeStamp) {
        if (_scrollController != null) {
          if ((_scrollController!.hasClients) &&
              (_scrollController!.position.haveDimensions)) {
            if (_scrollController!.position.maxScrollExtent == 0) {
              if (_paginatedApiResponse?.needToLoadMoreData() ?? true) {
                startApiCall(query: _query);
              }
            }
          }
        }
      },
    );

    emit(PaginatedApiCallSuccess<T>(data: _paginatedApiResponse?.data ?? []));
  }

  void reset({Map<String, String>? withQuery}) {
    if (withQuery != null) _query = withQuery;

    _paginatedApiResponse = null;
    emit(PaginatedApiCallInitial());
  }

  ScrollController? _scrollController;

  ScrollController initScrollController(
      {Map<String, String>? query, bool resetScrollController = false}) {
    if (query != null) _query = query;
    if (_scrollController != null && !resetScrollController) {
      return _scrollController!;
    } else {
      if (resetScrollController) {
        _scrollController?.dispose();
      }

      _scrollController = ScrollController();

      _scrollController?.addListener(() {
        if (_scrollController?.position.pixels ==
                _scrollController?.position.maxScrollExtent &&
            (_paginatedApiResponse?.needToLoadMoreData() ?? true)) {
          startApiCall(query: _query);
        }
      });
      // Verify if controller can be scrolled
      SchedulerBinding.instance.addPostFrameCallback(
        (timeStamp) {
          if (_scrollController != null) {
            if ((_scrollController!.hasClients) &&
                (_scrollController!.position.haveDimensions)) {
              if (_scrollController!.position.maxScrollExtent == 0) {
                if (_paginatedApiResponse?.needToLoadMoreData() ?? true) {
                  startApiCall(query: _query);
                }
              }
            }
          }
        },
      );
      return _scrollController!;
    }
  }

  @override
  Future<void> close() {
    _scrollController?.dispose();
    return super.close();
  }
}
