## 1.2.1
* Added `cancelToken` parameter to `doApiRequest` method to cancel API calls
* Updated dependencies

## 1.2.0
* **BREAKING** - Changed `ApiRequest` typedef to be a `Function` instead of a `Future` (impacts `ApiCallBuilder` widget)
* Added method to trigger API call again for `SingleApiCallCubit`
* Added _child_ parameter to `ApiCallBuilder` widget

## 1.1.9
Added `client` parameter to `ConnectionManager` constructor to eventually override the default http client for API calls.

## 1.1.8
Initial release on GitHub, increased dependencies. Requires Dart 3.

## 1.1.7
Added `mapStatusCodeFromResponse` parameter to `ConnectionManager` constructor to eventually override the http status code of API calls with a value from the body response.

## 1.1.6
Added `downloadProgress` parameter to `doApiRequest` method to be notified of bytes download progress during the API call.

## 1.1.5
Added `onTokenExpiredRuleOverride` parameter to `ConnectionManager` constructor.

## 1.1.4
Added `onResponseReceived` parameter to `ConnectionManager` constructor.

## 1.1.3
Added `filterMapResponseToDecodeContent` parameter to `doApiRequest` method to prefilter the response body json when trying to decode content with `decodeContentFromMap`.

## 1.1.2
* **BREAKING** - Added `reponseList` argument in builder attribute of `ApiCallBuilder`
* Fixed error parsing for graphQL response.


## 1.1.1

* Added `initialPage` parameter to `PaginatedApiCallBuilder`.
* Added possibility to set a new query filter when resetting the `PaginatedApiCallCubit` to initial state.

## 1.1.0

Added the `PaginatedApiCallBuilder` to  easily make paginated API calls.

## 1.0.9

Added a method to retrieve upload percentage for formData bodies.
## 1.0.8

* Added cookie manager to preserve cookies among API requests done with the same ConnectionManager.
* Added validateStatus method in doApiRequest to accept as valid also status codes different from 200-299.

## 1.0.7

Added timeout override for API calls.

## 1.0.6

Added graphql support for doApiRequest body.

## 1.0.5

Added utf8 decoding for API response instead of default decoding.

## 1.0.4

Added refresh token managemnt for ConnectionManager.

## 1.0.3

Added ApiBodyType to doApiRequest method to send formData and x-www-form-urlencoded body in API requests (use DIO package for the implementation of this two body types).

## 1.0.2

Added setSharedHeaders method to BaseConnectionManager class to add extra headers after init (such as auth token)

## 1.0.1

Added decodedBodyFromList property in PostApiResponse to decode incoming API response as List instead of Map

## 1.0.0

First stable release. This release the following implementations:

* ApiCallBuilder to easily integrate API calls in _build_ method with bloc
* Improved docs and ReadMe

## 0.0.1

Initial release. This package adds the following implementations:

* ConnectionManager to manage a shared manager for API calls
* A method doApiRequest for the ConnectionManager to actually execute an API request
* Decodable class to implement fromMap method to let the package decode the http response
