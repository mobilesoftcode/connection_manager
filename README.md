This package provides a simple implementation of a Connection Manager to do API request to a Server (REST or GraphQL). Furthermore, it provides an ApiCallBuilder widget to easily integrate API calls in the widget tree and a PaginatedApiCallBuilder widget to easily integrate paginated API calls in the widget tree.

## Features

This package contains: 
* **ConnectionManager** 
<br>
A class to make API requests, created setting a baseurl and headers to use for all the API calls.

* **PostApiResponse** 
<br>

A class to manage responses from the `ConnectionManager`, decoded by the provided class.

* **Decodable**
<br>

A class to implement to let this package decode custom classes from a Map.

* **ApiCallBuilder**
<br>

A widget to easily integrate API calls in the widget tree.

* **PaginatedApiCallBuilder**
<br>

A widget to easily integrate paginated API calls in the widget tree.

## Usage

Check the usage paragraph according to your needs.
<br>

### Setting up
Before using the `ConnectionManager`, it must be initialized providing a baseUrl and headers. It can be useful to save a single instance of the `ConnectionManager` to be used all through the app, for example as a singleton.
<br>

To initialize the class:

```dart
ConnectionManager(
    baseUrl: "https://my-base-url.com",
    constantHeaders: {
        "Content-Type": "application/json",
    },
    decodeErrorFromMap: CustomError.fromMapError, // Optional, to let the package try to automatically decode errors from server. It's a method passed as a tear off
    mapStatusCodeFromResponse: (map) => map?["code"], // Optional, you can use this method to map a code from body and use it to override the http status code.
    onTokenExpiredRuleOverride: (response) {
      if (response.statusCode == 500 && response.body.contains("missing auth")) {
        return true;
      }
      return false;
    },  /// Optional, this method can be used in combination with `onTokenExpired` to define a custom rule to trigger the `onTokenExpired` method. By default, `onTokenExpired` is fired when the http response has a 401 status code. Eventually, this rule can be expanded thanks to this method.
    onTokenExpired: () async {
      return await refreshToken(); // refreshToken is not a method of this package
    }, // A function fired when the http client gives a 401 response after an API call. It is used to refresh the auth token, if set, and after returning the new token the [ConnectionManager] will attempt the API call once again.
    onResponseReceived: (Response response) {
      print(response.body);
    },  // A function fired, if not _null_, when the `doApiRequest` method receives a response from the BE. This can be useful to manage broadly a `Response` the same way for every api call.
    returnCatchedErrorMessage: true, // Specify if the error message coming from the try-catch block in `doApiRequest` should be returned in the response (i.e. decoding errors). Default to _true_.
    duration: const Duration(seconds: 1), // Specify the timeout for all the API calls done with this [ConnectionManager]. Defaults to 1 minute.
    persistCookies: false, // If _true_, creates a persistent instance of a cookie manager to be used for all the API calls done with this [ConnectionManager]. Defaults to _false_.
    client: Client(), // If set, overrides the default http client for API calls
)
```

In the example above, `CustomError` is a local class that implements `Decodable` in this package and its `fromMapError` method. See `Decodable` documentation for further details.
<br>

You can store a single instance of the `ConnectionManager` as a Provider or as a singleton. Check this example:

``` dart
class NetworkProvider {
  final String baseUrl;

  // Connection Manager definition
  final _connectionManager = ConnectionManager<CustomError>(
      baseUrl: baseUrl,
      constantHeaders: {"Content-Type": "application/json"},
      decodeErrorFromMap: CustomError.fromMapError,
      onTokenExpired: () async {
        return await refreshToken(); // refreshToken() is not a method of this package
      },
      onResponseReceived: (Response response) {
        print(response.body);
      },
      returnCatchedErrorMessage: true,
   );

  // Connection Manager getter
  ConnectionManager<CustomError> get connectionManager => _connectionManager;
 }

 // Use the provider
 class MyApp extends StatelessWidget {
   @override build(BuildContext context) {
     return Provider(
       create: (context) => NetworkProvider(
         baseUrl: "https://test.com/api",
       ),
       child: Builder(
         builder: (context) {
           var networkProvider = context.read<NetworkProvider>();
           return Text(networkProvider.baseUrl);
         }
       ),
     );
   }
 }
```

### Modify ConnectionManager

Other than passing constant headers to the `ConnectionManager` constructor, it is possible to add/remove extra headers to be used for all the API calls by calling one of the following methods on the created instance.

``` dart
context.read<NetworkProvider>().connectionManager.setSharedHeaders({
  "Authorization" : "token"
});

context.read<NetworkProvider>().connectionManager.setAuthHeader("Bearer token");

context.read<NetworkProvider>().connectionManager.removeAuthHeader();
``` 

Furthermore, it is possibile to edit the baseurl
``` dart
context.read<NetworkProvider>().connectionManager.changeBaseUrl("https://test.com/api/v1");
```

### Make an api request
To make an API request simply call the method `doAPIRequest` on the `ConnectionManager`, passing all the required parameters, and eventually other headers or a body.
<br>

The method is asyncronous, and it will return a `PostApiResponse` as a `Future`, containing the decoded content, the http status code and eventually an error message.
<br>

Other than specifying the request type (get, post...), it is possible to specify the body type: json, formdata, graphQL... To do so, use the `bodyType` parameter (defaults to json type). Note: When passing a json body, it's mandatory to _json_ encode the Map, as follows.

``` dart
var response = await context.read<NetworkProvider>().connectionManager.doApiRequest(
  requestType: ApiRequestType.post,
  endpoint: "/test-endpoint",
  body: jsonEncode({
    "test": "test"
  }),
);
``` 

When using a _formData_ body, it's mandatory to pass it as a `Map<String,dynamic>`. To pass a file, use the `FileData` class provided by this library to create a file and add it as a vaue of the Map. It's left to the package to manage it correctly.

Whenn using a _graphQL_ body, it's mandatory to pass it as a [String]. Parameters must be passed as values in the string itself. The [ApiRequestType] should be _get_ for queries or anything else for _mutations_.

```dart
var postApiResponse = await context.read<NetworkProvider>().connectionManager.doApiRequest(
    requestType: ApiRequestType.get,
    bodyType: ApiBodyType.json, // Optional, the type of the body for the request (json, formdata...)
    endpoint: "/my-endpoint",
    headers: { // Optional, this Map headers are added to the ConnectionManager headers
        "Authentication": "xxx",
    },
    body: { // Optional, the body of the request
        "content": "xxx",
    },
    query: { // Optional, query paramters appended to the endpoint
        "query": "test",
    },
    decodeContentFromMap: User.fromMap, // Optional, a method to automatically decode the response model, of type [T], passed as _tear-off_
    filterMapResponseToDecodeContent: (mapResponse) {
      return mapResponse["items"];
    }, // Optional, a key from the original json response map (retrieved as argument of this method) can be specificied to try to the decode the content. This is useful, for example, when the response body has many nested keys but we need to decode a specific one, also deep in the json tree
    decodeErrorFromMapOverride: CustomError.fromMap, // Optional, a method to automatically decode the error response model, of type [E], passed as _tear-off_ that overrides the method specified in [ConnectionManager] constructor
    unescapeHtmlCodes: false, // Boolean value to eventually unescape html chars in response, defaults to _false_
    tryRefreshToken: true, // Boolean value to refresh the auth token and retry the API call when the http status code is 401. Defaluts to _true_.
    useUtf8Decoding: false, // Boolean value to eventyally decode the response with utf8 directly to the bytes, ignoring the body. Defaluts to _false_.
    timeout: const Duration(seconds: 30), // the timeout for the API call, overrides that of the [ConnectionManager].
    uploadPercentage: (percentage) => print(percentage), // it's used to retrieve the upload percentage status for _formData_ bodies. It's ignored for other _bodyTypes_.
    validateStatus: (status) => true, // it's used to evaluate response status code and manage it as success/error accordingly. Simply return _true_ or _false_ depending on the _status_. Note that status codes between 200 and 299 are always accepted as successfull.
    downloadProgress: (downloadedBytes, totalBytes, percentage) => print(percentage), // Optional, it's used to retrieve the download percentage status for responses from BE. It has three arguments: download bytes, total bytes count and percentage downloaded.
    cancelToken: null, // Optional, it's eventually used to cancel the http request before awaiting termination. It does not work for _graphql_ requests.

)
```

### PostApiResponse
You can use the `PostApiResponse` class to easily return the response data of the specified type.

```dart
PostApiResponse<User, GenericError>(
    decodedBody: User, // The body eventually decoded in the provided class, if success
    decodedBodyAsList: List<User>, // The body eventually decoded in the provided class a list, if success (useful when API response is a List instead of a Map)
    decodedErrorBody: GenericError, // The body eventually decoded in the provided error class, if error
    rawValue: dynamic, // The raw body of the response
    originalResponse: http.Response, // The original http response of the API call
    statusCode: int, // The http response status cose
    hasError: bool, // A boolean value to indicate if there was an error
    message: String?, // A String containing the error message, if any
)
```

### ApiCallBuilder
To easily integrate a widget that does an API call in your widget tree, you can use `ApiCallBuilder`. It's a widget that using bloc shows a loader while performing the provided API call and then returns the response in a builder that must return the widget to show on completion. The `ApiCallBuilder` must be used together with the `ConnectionManager` as it accept as input the `doApiRequest` method as shown below.

 ``` dart
 ApiCallBuilder<User, Error>(
   apiCall: () => context.read<NetworkProvider>().doApiRequest(
     requestType: ApiRequestType.get,
     endpoint: "/test-endpoint",
   ),
   builder: (context, response, responseList) {
     return Text(response.toString());
   },
   loaderBuilder: (context) => Loader(), // Optional, defaults to a black loader spinner
   errorBuilder: (context, errorMessage) => Text(errorMessage ?? "Generic error"), // Optional, defaults to a Text displaying the error message
   emptyDataBuilder: (context) => Text("No data"),  /// Optional, a widget to manage the empty state can be provided. If not provided, the `builder` will be used
 );
 ```

As soon as the widget is created, the api call is triggered. If you want to trigger the API call again, simply call:

``` dart
  context.read<SingleApiCallCubit<Decodable,Decodable>>().startApiCall();
```

Note that you can specify a `child` argument to always show some widgets while data is loading. Check the documentation for further details.

 ### PaginatedApiCallBuilder
To manage transparently a paginated API call in the widget tree, you can use `PaginatedApiCallBuilder`. It shows a loading widget while performing the request and provides access to the response in the `builder` parameter, to show a proper widget on http call completion. Furthermore, it can manage pagination while scrolling.

It must be used with the [ConnectionManager], that is what manages API call and states through a bloc component.

[T] and [E] are, respectively, the class to decode in the success response and the class to decode for an error response. If not provided, the builder will have a generic [Object] as argument, that then should be casted to use.

``` dart
  Future<PaginatedAPIResponse<User, Error>> doApiRequest(
     int page, Map<String, String>? query) async {
   var response = await context.read<NetworkProvider>().connectionManager.doApiRequest(
     requestType: ApiRequestType.get,
     endpoint: "/test-endpoint",
     decodeContentFromMap: User.fromMap,
   );
   if (response.hasError) {
     return PaginatedAPIResponse.error(response: response);
   }

   return PaginatedAPIResponse.success(response.decodedBody.data ?? [], // Note that `response.decodedBody.data` depends on your decoded model, this is an example
       response: response, page: page, pageSize: 25);
 }

 PaginatedApiCallBuilder<User, Error>(
   apiCall: doApiRequest,
   builder: (context, response) {
     return Text(response.toString());
   },
   loaderBuilder: (context) => Text("Loading"), // Optional, the widget to show while fetching data
   errorBuilder: (context, errorMessage) => Text(errorMessage ?? "Generic error"), // Optional, the widget to show if the api calls terminates with errors, eventually with an error message
   initialQuery: {'limit':'10'}, // Optionally, a query for the api calls can be set as default. It can be overriden when calling `startApiCall` directly or when initializing the [ScrollController].
   initialPage: 0, // The initial page for pagination. Usually pagination starts from 0 (default value), but a different number can be specified to be used as first page.
 );
 ```

 As soon as the widget is created, the api call for the first page is triggered. The package itself is responsible of managing pages, so to execute new api calls for sequent pages, you simply call:

 ``` dart
  context.read<PaginatedApiCallCubit<Decodable, Decodable>>()>.startApiCall();
 ```

 Where `Decodable` should be the [T] and [E] classes you defined in the `PaginatedApiCallBuilder` constructors. Note that to use `context.read()` method you must import the [provider package](https://pub.dev/packages/provider). Check the docs to know how to properly use it.

 <br>

 To reset data simply call:
  ``` dart
  context.read<PaginatedApiCallCubit<Decodable, Decodable>>()>.reset();
 ```

 Eventually, also a new query filter can be set, as follows:
  ``` dart
  context.read<PaginatedApiCallCubit<Decodable, Decodable>>()>.reset(withQuery: {"pageSize":"10"});
 ```

 <br>

To enable automatic pagination on scrolling, pass a controller to the ScrollView you want to paginated as shown in the following example:
  ``` dart
  return ListView(
    controller: context.read<PaginatedApiCallCubit<Decodable, Decodable>>()>.initScrollController();
    ...
  );
 ```

 <br>

 Either in the `startApiCall` method or the `initScrollController` method, you can override the initial query set in the `PaginatedApiCallBuilder` constructor by passing an optional [Map<String,String>] argument. You can than access this query, as well as the new page calculated by the package, when specifying the method to pass as the `apiCall` in the `PaginatedApiCallBuilder` constructor, as shown in the first piece of code of this paragraph.

 <br>

 You can specify that instead of appending new data to the original response, the package should entirely wipe old data and substitute it with data from the new page, as shown in the following example:
 
 ``` dart
  context.read<PaginatedApiCallCubit<Decodable, Decodable>>()>.startApiCallAndReplaceData(); 
 ```

 If you do not specify arguments, by default the next page will be fetched. You can however specify a page, or that the pagination should go back/forward from actual page leaving calculations to the package. If you do not provide `newPage` than the next page is taken by default if `goToPreviousPage` is not _true_.

 ### Test
For test purposes or to simulate mocked responses, you can use `ConnectionManagerStub`. It is equivalent to the `ConnectionManager` (both extend `BaseConnectionManager`), with some little differences explained below.
```dart
final _connectionManager = ConnectionManagerStub<CustomError>(
    decodeErrorFromMap: CustomError.fromMapError,
    onTokenExpired: () async {
      return await refreshToken(); // refreshToken() is not a method of this package
    },
    onResponseReceived: (Response response) {
      print(response.body);
    },
    returnCatchedErrorMessage: true,
    awaitResponse: true, // Optionally, simulate waiting 2 seconds for receiving response from BE
    responseStatusCode: 500, /// Optionally, override all the http response status code for the API requests with a custom status code. If _null_ does not override status codes.
  );
```

When creating an API request, you should pass a json file from the project assets to be used as response from an API call instead of the usual endpoint. The other parameters will be used as for a real API request.
```dart
var postApiResponse = await context.read<NetworkProvider>().connectionManager.doApiRequest(
    requestType: ApiRequestType.get,
    bodyType: ApiBodyType.json, // Optional, the type of the body for the request (json, formdata...)
    endpoint: "mocks/test.json",
)
```

Furthermore, when using `ConnectionManagerStub` you can specify a different status code expected for the next http response by calling the `mockResponseStatus` method. Note that response status code is reset to 200 after the following API call.
```dart
final res = await context.read<NetworkProvider>().connectionManager
  .mockResponseStatus(statusCode: 404)
  .doApiRequest(endpoint: "mocks/test.json");
```


## Additional information

This package is mantained by the Competence Center Flutter of Mobilesoft Srl.
