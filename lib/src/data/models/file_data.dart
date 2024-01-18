/// This class is used to pass files in formData body
class FileData {
  /// The file bytes for form data body
  final List<int> bytes;

  /// The file name for form data body
  final String? name;

  /// Used to pass files in formData body for API calls
  FileData({required this.bytes, this.name});
}
