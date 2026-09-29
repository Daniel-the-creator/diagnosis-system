import '../models/invoice_model.dart';
import '../models/payment_model.dart';
import '../services/firestore/billing_firestore_service.dart';

class BillingRepository {
  BillingRepository(this._service);
  final BillingFirestoreService _service;

  String generateInvoiceId() => _service.generateInvoiceId();
  String generatePaymentId() => _service.generatePaymentId();

  Future<void> saveInvoice(InvoiceModel invoice) => _service.saveInvoice(invoice);

  Future<InvoiceModel?> getInvoiceById(String id) => _service.getInvoiceById(id);

  Future<InvoiceModel?> getInvoiceByVisitId(String visitId) =>
      _service.getInvoiceByVisitId(visitId);

  Future<void> updateInvoice(String id, Map<String, dynamic> data) =>
      _service.updateInvoice(id, data);

  Future<void> recordPayment({
    required PaymentModel payment,
    required InvoiceModel invoice,
  }) =>
      _service.recordPayment(payment: payment, invoice: invoice);

  Stream<InvoiceModel?> streamInvoiceForVisit(String visitId) =>
      _service.streamInvoiceForVisit(visitId);

  Stream<List<InvoiceModel>> streamPatientInvoices(String patientId) =>
      _service.streamPatientInvoices(patientId);

  Stream<List<InvoiceModel>> streamPendingInvoices() =>
      _service.streamPendingInvoices();

  Stream<List<InvoiceModel>> streamAllInvoices() =>
      _service.streamAllInvoices();

  Stream<List<PaymentModel>> streamInvoicePayments(String invoiceId) =>
      _service.streamInvoicePayments(invoiceId);

  Stream<List<PaymentModel>> streamPatientPayments(String patientId) =>
      _service.streamPatientPayments(patientId);
}
