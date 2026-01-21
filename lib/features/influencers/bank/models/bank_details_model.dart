class BankDetails {
  String bankName;
  String accountHolderName;
  String iban;
  String accountNumber;
  String? ibanCertificateUrl;
  String status; // 'pending', 'approved', 'rejected'
  String? rejectionReason;

  BankDetails({
    required this.bankName,
    required this.accountHolderName,
    required this.iban,
    required this.accountNumber,
    this.ibanCertificateUrl,
    required this.status,
    this.rejectionReason,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankName: json['bank_name'] ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      iban: json['iban'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ibanCertificateUrl: json['iban_certificate_url'],
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() => {
    'bank_name': bankName,
    'account_holder_name': accountHolderName,
    'iban': iban,
    'account_number': accountNumber,
    'iban_certificate_url': ibanCertificateUrl,
  };
}