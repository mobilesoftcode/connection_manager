import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../connection_manager.dart';
import '../logic/cubit/single_api_call/single_api_call_cubit.dart';
import '../ui/error_box.dart';
import 'loader.dart';

/// This widget helps to manage transparently an API call in the widget tree
/// showing a loading widget while performing the request and providing access
/// to the response in the `builder` parameter, to show a proper widget on http call completion.
///
/// It must be used with the [ConnectionManager], that is what manages API call
/// and states through a bloc component.
///
/// [T] and [E] are, respectively, the class to decode in the success response and the
/// class to decode for an error response.
/// If not provided, the builder will have a generic [Object] as argument, that then
/// should be casted to use.
class ApiCallBuilder<T extends Decodable, E extends Decodable>
    extends StatelessWidget {
  /// The api call to perform with the [ConnectionManager]. It is the same apicall
  /// with [doApiRequest] that is normally performmed by the [ConnectionManager]
  final APIRequest<T, E> apiCall;

  /// The builder for a widget when the API call is successfull.
  /// The `response` argument is the class decoded by the [ConnectionManager].
  /// The `responseList` argument is the class decoded as a list.
  final Widget Function(
      BuildContext context, T? response, List<T>? responseList) builder;

  /// Optionally, a widget for the loading state can be provided. If _null_, a default
  /// black loading spinner is shown.
  final Widget Function(BuildContext context)? loaderBuilder;

  /// Optionally, a widget to manage the error state can be provided. The `errorMessage`
  /// argument is the error retrieved by the API call (if any). If not provided,
  /// a default error text is shown.
  final Widget Function(BuildContext context, String? errorMessage)?
      errorBuilder;

  /// This widget helps to manage transparently an API call in the widget tree
  /// showing a loading widget while performing the request and providing access
  /// to the response in the `builder` parameter, to show a proper widget on http call completion.
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
  /// ApiCallBuilder<User, Error>(
  ///   apiCall: context.read<NetworkProvider>().connectionManager.doApiRequest(
  ///     requestType: ApiRequestType.get,
  ///     endpoint: "/test-endpoint",
  ///   ),
  ///   builder: (context, response) {
  ///     return Text(response.toString());
  ///   },
  /// );
  /// ```
  const ApiCallBuilder({
    Key? key,
    required this.apiCall,
    required this.builder,
    this.loaderBuilder,
    this.errorBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SingleApiCallCubit<T, E>(apiCall: apiCall),
      child: BlocBuilder<SingleApiCallCubit<T, E>, SingleApiCallState>(
        builder: (context, state) {
          if (state is ApiCallInitialState) {
            if (loaderBuilder != null) {
              return loaderBuilder!(context);
            }
            return const LoaderWidget();
          } else if (state is ApiCallLoadingState) {
            if (loaderBuilder != null) {
              return loaderBuilder!(context);
            }
            return const LoaderWidget();
          } else if (state is ApiCallErrorState) {
            if (errorBuilder != null) {
              return errorBuilder!(context, state.errorMessage);
            }
            return ErrorBox(
              errorMessage: state.errorMessage,
            );
          } else if (state is ApiCallLoadedState<T, E>) {
            return builder(context, state.response.decodedBody,
                state.response.decodedBodyAsList);
          }
          return const ErrorBox();
        },
      ),
    );
  }
}
