/// CRUD type for API request.
enum ApiRequestType {
  get,
  post,
  put,
  patch,
  delete,
}

/// Type for the body of the API call
enum ApiBodyType {
  json,
  xWwwFormUrlencoded,
  formData,
  graphQL,
}
