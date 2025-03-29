class FilmanAuthException extends Error {
  final String message;

  FilmanAuthException(this.message);

  @override
  String toString() {
    return 'FilmanAuthException: $message';
  }
}
