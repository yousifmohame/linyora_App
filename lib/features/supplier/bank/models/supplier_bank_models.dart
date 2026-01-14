class SupplierBankDetails {
  final String bankName;
  final String accountHolderName;
  final String iban;
  final String? accountNumber;
  final String? ibanCertificateUrl;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;

  SupplierBankDetails({
    required this.bankName,
    required this.accountHolderName,
    required this.iban,
    this.accountNumber,
    this.ibanCertificateUrl,
    required this.status,
    this.rejectionReason,
  });

  factory SupplierBankDetails.fromJson(Map<String, dynamic> json) {
    return SupplierBankDetails(
      bankName: json['bank_name'] ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      iban: json['iban'] ?? '',
      accountNumber: json['account_number'],
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