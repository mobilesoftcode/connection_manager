import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../connection_manager.dart';
import '../ui/error_box.dart';
import 'loader.dart';

/// This widget helps to manage transparently a paginated API call in the widget tree
/// showing a loading widget while performing the request and providing access
/// to the response in the `builder` parameter, to show a proper widget on http call completion.
///
/// Furthermore, it can manage pagination while scrolling.
///
/// It must be used with the [ConnectionManager], that is what manages API call
/// and states through a bloc component.
///
/// [T] and [E] are, respectively, the class to decode in the success response and the
/// class to decode for an error response.
/// If not provided, the builder will have a generic [Object] as argument, that then
/// should be casted to use.
class PaginatedApiCallBuilder<T extends Decodable, E extends Decodable>
    extends StatelessWidget {
  /// The api call to retrieve paginated data. The [ConnectionManager]'s [doApiRequest]
  /// method can be used to retrieve a single response, that then must be converted
  /// to a [PaginatedAPIResponse] type.
  final PaginatedAPIRequest<T, E> apiCall;

  /// The builder for a widget when the API call is successfull.
  /// The `response` argument is the class decoded by the [ConnectionManager].
  final Widget Function(BuildContext context, List<T>? response) builder;

  /// Optionally, a widget for the loading state can be provided. If _null_, a default
  /// black loading spinner is shown.
  final Widget Function(BuildContext context)? loaderBuilder;

  /// Optionally, a widget to manage the error state can be provided. The `errorMessage`
  /// argument is the error retrieved by the API call (if any). If not provided,
  /// a default error text is shown.
  final Widget Function(BuildContext context, String? errorMessage)?
      errorBuilder;

  /// Optionally, a widget to manage the empty state can be provided. If not provided,
  /// the `builder` will be used.
  final Widget Function(BuildContext context)? emptyDataBuilder;

  /// Optionally, a query for the api calls can be set as default.
  /// It can be overriden when calling `startApiCall` directly or when initializing the [ScrollController].
  final Map<String, String>? initialQuery;

  /// The initial page for pagination. Usually pagination starts from 0 (default value),
  /// but a different number can be specified to be used as first page.
  final int initialPage;

  /// This widget helps to manage transparently a paginated API call in the widget tree
  /// showing a loading widget while performing the request and providing access
  /// to the response in the `builder` parameter, to show a proper widget on http call completion.
  ///
  /// Furthermore, it can manage pagination while scrolling.
  ///
  /// It must be used with the [ConnectionManager], that is what manages API call
  /// and states through a bloc component.
  ///
  /// [T] and [E] are, respectively, the class to decode in the success response and the
  /// class to decode for an error response.
  /// If not provided, the builder will have a generic [Object] as argument, that then
  /// should be casted to use.
  ///
  /// ``` dart
  ///  Future<PaginatedAPIResponse<User, Error>> doApiRequest(
  ///     int page, Map<String, String>? query) async {
  ///   var response = await context.read<NetworkProvider>().connectionManager.doApiRequest(
  ///     requestType: ApiRequestType.get,
  ///     endpoint: "/test-endpoint",
  ///     decodeContentFromMap: User.fromMap,
  ///   );
  ///   if (response.hasError) {
  ///     return PaginatedAPIResponse.error(response: response);
  ///   }
  ///
  ///   return PaginatedAPIResponse.success(response.decodedBody.data ?? [], // Note that `response.decodedBody.data` depends on your decoded model, this is an example
  ///       response: response, page: page, pageSize: 25);
  /// }
  ///
  /// PaginatedApiCallBuilder<User, Error>(
  ///   apiCall: doApiRequest,
  ///   builder: (context, response) {
  ///     return Text(response.toString());
  ///   },
  /// );
  /// ```
  const PaginatedApiCallBuilder({
    Key? key,
    required this.apiCall,
    required this.builder,
    this.loaderBuilder,
    this.errorBuilder,
    this.initialQuery,
    this.emptyDataBuilder,
    this.initialPage = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaginatedApiCallCubit<T, E>(
          apiCall: apiCall, query: initialQuery, initialPage: initialPage),
      child: BlocBuilder<PaginatedApiCallCubit<T, E>, PaginatedApiCallState>(
        builder: (context, state) {
          if (state is PaginatedApiCallInitial) {
            BlocProvider.of<PaginatedApiCallCubit<T, E>>(context)
                .startApiCall();
            if (loaderBuilder != null) {
              return loaderBuilder!(context);
            }
            return const LoaderWidget();
          } else if (state is PaginatedApiCallLoading) {
            if (loaderBuilder != null) {
              return loaderBuilder!(context);
            }
            return const LoaderWidget();
          } else if (state is PaginatedApiCallError) {
            if (errorBuilder != null) {
              return errorBuilder!(context, state.errorMessage);
            }
            return ErrorBox(
              errorMessage: state.errorMessage,
            );
          } else if (state is PaginatedApiCallLoadingNewPage<T>) {
            return Column(
              children: [
                Expanded(child: builder(context, state.previousData)),
                loaderBuilder != null
                    ? loaderBuilder!(context)
                    : const LoaderWidget(),
              ],
            );
          } else if (state is PaginatedApiCallEmpty) {
            if (emptyDataBuilder != null) {
              return emptyDataBuilder!(context);
            }
            return Column(
              children: [
                Expanded(child: builder(context, [])),
              ],
            );
          } else if (state is PaginatedApiCallSuccess<T>) {
            return Column(
              children: [
                Expanded(child: builder(context, state.data)),
              ],
            );
          }
          return const ErrorBox();
        },
      ),
    );
  }
}
