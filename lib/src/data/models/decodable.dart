/// [Decodable] is an abstract class that exposes a factory method to override
/// to be used as decodable object in API call.
///
/// Implementing the [Decodable.fromMap] method, it's possible to demandate to the
/// [ConnectionManager] the decoding of the json string retrieved by the server through API call,
/// if any.
///
/// The [ConnectionManager] itself is responsible to convert the json string to a map
/// and passing it to the function.
///
/// **Tip**:
/// If you are using Visual Studio Code, download the "Dart Data Class Generator"
/// and use it to easily generate and override the [fromMap] method.
abstract class Decodable {
  Decodable.fromMap(Map<String, dynamic> map);
  Decodable.fromMapError(int statusCode, Map<String, dynamic> map);
}
