class BankDetails {
  String bankName;
  String accountHolderName;
  String iban;
  String accountNumber;
  String ibanCertificateUrl;
  String status; // pending, approved, rejected
  String? rejectionReason;

  BankDetails({
    this.bankName = '',
    this.accountHolderName = '',
    this.iban = '',
    this.accountNumber = '',
    this.ibanCertificateUrl = '',
    this.status = 'pending',
    this.rejectionReason,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankName: json['bank_name'] ?? '',
      accountHolderName: json['account_holder_name'] ?? '',
      iban: json['iban'] ?? '',
      accountNumber: json['account_number'] ?? '',
      ibanCertificateUrl: json['iban_certificate_url'] ?? '',
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejection_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bank_name': bankName,
      'account_holder_name': accountHolderName,
      'iban': iban,
      'account_number': accountNumber,
      'iban_certificate_url': ibanCertificateUrl,
      // status لا يرسل عند التحديث عادة، السيرفر يحدده
    };
  }
}