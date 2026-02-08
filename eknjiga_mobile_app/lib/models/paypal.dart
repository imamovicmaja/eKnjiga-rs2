class PaypalCreateOrderResult {
  final String id;
  final String status;
  final String approveLink;

  PaypalCreateOrderResult({
    required this.id,
    required this.status,
    required this.approveLink,
  });

  factory PaypalCreateOrderResult.fromJson(Map<String, dynamic> json) {
    return PaypalCreateOrderResult(
      id: json['id'] as String,
      status: json['status'] as String,
      approveLink: json['approveLink'] as String,
    );
  }
}
