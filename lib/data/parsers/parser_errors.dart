enum ParserErrorCode {
  invalidInput,
  pairNotFound,
  metadataNotFound,
}

class ParserException implements Exception {
  ParserException(this.code, this.message);

  final ParserErrorCode code;
  final String message;

  @override
  String toString() => 'ParserException(code: $code, message: $message)';
}
