import 'package:flutter/material.dart';
import '../../../core/services/translation_extension.dart';
import '../../../core/theme/app_theme.dart';
import '../services/admin_service.dart';

class LoanDetailsScreen extends StatefulWidget {
  final int loanId;
  const LoanDetailsScreen({super.key, required this.loanId});

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
  Map<String, dynamic>? _loan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoanDetails();
  }

  Future<void> _loadLoanDetails() async {
    setState(() => _isLoading = true);
    // In a real app, you'd have a dedicated function in AdminService to get a single loan by its ID.
    // This would be more efficient than fetching all loans.
    final allLoans = await AdminService.getAllLoans();
    final loan = allLoans.firstWhere(
      (l) => l['id'] == widget.loanId,
      orElse: () => {},
    );

    if (mounted) {
      setState(() {
        _loan = loan.isNotEmpty ? loan : null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('loan_details_title'.tr(context)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loan == null
          ? Center(child: Text('loan_not_found'.tr(context)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailCard(),
                  const SizedBox(height: 16),
                  _buildApplicantCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'loan_summary'.tr(context),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _infoRow('status'.tr(context), _loan!['status'] ?? '-'),
            _infoRow(
              'principal_label'.tr(context),
              'TZS ${_formatAmount(_loan!['amount'])}',
            ),
            _infoRow(
              'interest_rate'.tr(context),
              '${_loan!['interest_rate']}%',
            ),
            _infoRow(
              'total_repayment'.tr(context),
              'TZS ${_formatAmount(_loan!['total_amount'])}',
            ),
            _infoRow('purpose_label'.tr(context), _loan!['purpose'] ?? '-'),
            if (_loan!['guarantor'] != null && _loan!['guarantor'].isNotEmpty)
              _infoRow('guarantor_label'.tr(context), _loan!['guarantor']),
            const Divider(height: 24),
            _infoRow(
              'application_date'.tr(context),
              _formatDate(_loan!['created_at']),
            ),
            if (_loan!['approval_date'] != null)
              _infoRow(
                'treasurer_approval_date'.tr(context),
                _formatDate(_loan!['approval_date']),
              ),
            if (_loan!['confirmation_date'] != null)
              _infoRow(
                'admin_confirmation_date'.tr(context),
                _formatDate(_loan!['confirmation_date']),
              ),
            if (_loan!['rejection_reason'] != null &&
                _loan!['rejection_reason'].isNotEmpty)
              _infoRow(
                'rejection_reason'.tr(context),
                _loan!['rejection_reason'],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicantCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'applicant_details'.tr(context),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(height: 24),
            _infoRow(
              'name'.tr(context),
              '${_loan!['first_name']} ${_loan!['last_name']}',
            ),
            _infoRow('phone'.tr(context), _loan!['phone_number'] ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0';
    final num value = amount is num
        ? amount
        : num.tryParse(amount.toString()) ?? 0;
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
