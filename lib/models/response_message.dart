class ResponseMessage {
  final String message;
  final bool isSuccess;

  ResponseMessage({
    required this.message,
    required this.isSuccess,
  });

  factory ResponseMessage.fromJson(Map<String, dynamic> json) {
    return ResponseMessage(
      message: json['message'] ?? '',
      isSuccess: json['isSuccess'] ?? false,
    );
  }
}