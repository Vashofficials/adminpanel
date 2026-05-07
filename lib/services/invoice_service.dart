import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/booking_models.dart';

/// Professional GST-compliant dual invoice generator.
class InvoiceService {
  // ── Company constants ──────────────────────────────────────────────────
  static const _companyName = 'Chayan Karo India Private Limited';
  static const _cin = 'U74900UP2025PTC217323';
  static const _gstin = '09AAMCC4582G1ZB';
  static const _companyAddress =
      '610/003, Keshavnagar, Sitapur Road,\nLucknow, Uttar Pradesh - 226020, India';
  static const _companyEmail = 'akravanassociates@gmail.com';
  static const _hsnCode = '998599';

  // ── Bank constants ─────────────────────────────────────────────────────
  static const _beneficiaryName = 'Chayan Karo India Private Limited';
  static const _bankName = 'ICICI Bank Limited';
  static const _accountNo = '465105000195';
  static const _ifsc = 'ICIC0004651';
  static const _branch = 'Sector J Aliganj, Lucknow';

  static const _rs = 'Rs.';

  // ── Colors ─────────────────────────────────────────────────────────────
  static const _primary = PdfColor.fromInt(0xFFEF7822);
  static const _primaryLight = PdfColor.fromInt(0xFFFFF3E8);
  static const _dark = PdfColor.fromInt(0xFF1E293B);
  static const _grey = PdfColor.fromInt(0xFF64748B);
  static const _divider = PdfColor.fromInt(0xFFCBD5E1);

  // ── Invoice number: CKIPL/26-27/A8O83C ─────────────────────────────────
  static String _invoiceNumber(String prefix, String bookingRef) {
    final now = DateTime.now();
    final fy1 = now.month >= 4 ? now.year % 100 : (now.year - 1) % 100;
    final fy2 = fy1 + 1;
    return '$prefix/${fy1.toString().padLeft(2, '0')}-${fy2.toString().padLeft(2, '0')}/$bookingRef';
  }

  // ── Font loading (cached) ──────────────────────────────────────────────
  static pw.Font? _cachedFont;
  static pw.Font? _cachedBoldFont;

  static Future<pw.Font> _getFont() async {
    _cachedFont ??= await PdfGoogleFonts.notoSansRegular();
    return _cachedFont!;
  }

  static Future<pw.Font> _getBoldFont() async {
    _cachedBoldFont ??= await PdfGoogleFonts.notoSansBold();
    return _cachedBoldFont!;
  }

  static Future<pw.ThemeData> _buildTheme() async {
    return pw.ThemeData.withFont(
      base: await _getFont(),
      bold: await _getBoldFont(),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  PUBLIC: Platform TAX INVOICE
  // ══════════════════════════════════════════════════════════════════════
  static Future<void> printPlatformInvoice(BookingModel booking) async {
    final theme = await _buildTheme();
    final pdf = pw.Document(theme: theme);
    final svgRaw = await _loadLogo();
    final now = DateTime.now();
    final invoiceNo = _invoiceNumber('CKIPL', booking.bookingRef);

    final grandTotal = booking.actualAmount;
    final platformAmount = grandTotal * 0.20;
    final cgst = platformAmount * 0.09;
    final sgst = platformAmount * 0.09;
    final invoiceTotal = platformAmount + cgst + sgst;

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      theme: theme,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader(svgRaw, 'TAX INVOICE', invoiceNo, now, booking),
          pw.SizedBox(height: 18),
          _sectionDivider(),
          pw.SizedBox(height: 14),
          _buildBillToSection(booking, now),
          pw.SizedBox(height: 14),
          _sectionDivider(),
          pw.SizedBox(height: 14),
          _buildPlatformTable(platformAmount),
          pw.SizedBox(height: 14),
          _sectionDivider(),
          pw.SizedBox(height: 12),
          _buildAmountSummary([
            _SummaryRow('Sub Total', platformAmount),
            _SummaryRow('CGST @ 9%', cgst),
            _SummaryRow('SGST @ 9%', sgst),
          ], invoiceTotal),
          pw.SizedBox(height: 6),
          _amountInWords(invoiceTotal),
          pw.Spacer(),
          _sectionDivider(),
          pw.SizedBox(height: 12),
          _buildBankDetails(),
          pw.SizedBox(height: 14),
          _sectionDivider(),
          pw.SizedBox(height: 10),
          _buildFooter('Thanks for your business.'),
        ],
      ),
    ));

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'CKIPL_${booking.bookingRef}',
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  PUBLIC: Provider INVOICE
  // ══════════════════════════════════════════════════════════════════════
  static Future<void> printProviderInvoice(BookingModel booking) async {
    final theme = await _buildTheme();
    final pdf = pw.Document(theme: theme);
    final svgRaw = await _loadLogo();
    final now = DateTime.now();
    final invoiceNo = _invoiceNumber('SP', booking.bookingRef);

    final grandTotal = booking.actualAmount;
    final providerAmount = grandTotal * 0.80;

    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      theme: theme,
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildHeader(
              svgRaw, 'PROVIDER INVOICE', invoiceNo, now, booking),
          pw.SizedBox(height: 18),
          _sectionDivider(),
          pw.SizedBox(height: 14),
          // Bill To + Provider Info side-by-side
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _billToBlock(booking)),
              pw.SizedBox(width: 30),
              pw.Expanded(child: _providerInfoBlock(booking)),
            ],
          ),
          pw.SizedBox(height: 14),
          _sectionDivider(),
          pw.SizedBox(height: 14),
          _buildProviderTable(booking),
          pw.SizedBox(height: 14),
          _sectionDivider(),
          pw.SizedBox(height: 12),
          _buildAmountSummary([
            _SummaryRow('Sub Total (Provider Share 80%)', providerAmount),
          ], providerAmount),
          pw.SizedBox(height: 6),
          _amountInWords(providerAmount),
          pw.Spacer(),
          _sectionDivider(),
          pw.SizedBox(height: 12),
          _buildBankDetails(),
          pw.SizedBox(height: 14),
          _sectionDivider(),
          pw.SizedBox(height: 10),
          _buildFooter('Payment to be settled to service provider'),
        ],
      ),
    ));

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'SP_${booking.bookingRef}',
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ══════════════════════════════════════════════════════════════════════

  static Future<String> _loadLogo() async {
    try {
      return await rootBundle.loadString('assets/logo.svg');
    } catch (_) {
      return '';
    }
  }

  static String _fmt(double amount) => '$_rs ${amount.toStringAsFixed(2)}';

  /// Section divider — thin grey line
  static pw.Widget _sectionDivider() =>
      pw.Container(height: 0.5, color: _divider);

  // ── HEADER (identical for both invoices) ───────────────────────────────
  static pw.Widget _buildHeader(String svgRaw, String title, String invoiceNo,
      DateTime date, BookingModel booking) {
    return pw.Column(children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // LEFT: Logo + Company info
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (svgRaw.isNotEmpty)
                  pw.SizedBox(
                      width: 110,
                      height: 55,
                      child: pw.SvgImage(svg: svgRaw)),
                pw.SizedBox(height: 6),
                pw.Text(_companyName,
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: _primary)),
                pw.SizedBox(height: 3),
                pw.Text('CIN: $_cin',
                    style: const pw.TextStyle(fontSize: 7, color: _grey)),
                pw.Text(_companyAddress,
                    style: const pw.TextStyle(fontSize: 7, color: _grey)),
                pw.Text('GSTIN: $_gstin',
                    style: const pw.TextStyle(fontSize: 7, color: _grey)),
                pw.Text('Email: $_companyEmail',
                    style: const pw.TextStyle(fontSize: 7, color: _grey)),
              ],
            ),
          ),
          pw.SizedBox(width: 20),
          // RIGHT: Invoice title + meta
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: _dark)),
              pw.SizedBox(height: 8),
              _metaRow('Invoice No', invoiceNo),
              _metaRow('Invoice Date', DateFormat('dd-MMM-yyyy').format(date)),
              _metaRow('Booking Ref', booking.bookingRef),
              _metaRow(
                  'Place of Supply', booking.address?.state ?? 'Uttar Pradesh'),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Container(height: 2, color: _primary),
    ]);
  }

  static pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('$label: ',
              style: const pw.TextStyle(fontSize: 8, color: _grey)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  // ── BILL TO SECTION ────────────────────────────────────────────────────
  static pw.Widget _buildBillToSection(BookingModel booking, DateTime date) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _billToBlock(booking)),
        pw.SizedBox(width: 30),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _sectionLabel('PAYMENT INFO'),
              pw.SizedBox(height: 4),
              pw.Text('Status: ${booking.paymentStatus}',
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text('Method: ${booking.paymentMode}',
                  style: const pw.TextStyle(fontSize: 9)),
              pw.Text(
                  'Booking Date: ${DateFormat('dd-MMM-yyyy').format(DateTime.tryParse(booking.bookingDate) ?? date)}',
                  style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _billToBlock(BookingModel booking) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionLabel('BILL TO'),
        pw.SizedBox(height: 4),
        pw.Text(booking.customerName,
            style: pw.TextStyle(
                fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.Text(booking.customerPhone,
            style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 2),
        pw.Text(booking.address?.fullFormattedAddress ?? '',
            style: const pw.TextStyle(fontSize: 8, color: _grey)),
      ],
    );
  }

  static pw.Widget _providerInfoBlock(BookingModel booking) {
    final p = booking.provider;
    final cat = booking.services.isNotEmpty
        ? booking.services.first.categoryName
        : 'N/A';
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _primaryLight,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _primary, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _sectionLabel('SERVICE PROVIDER'),
          pw.SizedBox(height: 4),
          pw.Text(p != null ? '${p.firstName} ${p.lastName}' : 'N/A',
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.Text(p?.mobile ?? '',
              style: const pw.TextStyle(fontSize: 9)),
          pw.Text('Category: $cat',
              style: const pw.TextStyle(fontSize: 8, color: _grey)),
        ],
      ),
    );
  }

  static pw.Widget _sectionLabel(String text) {
    return pw.Text(text,
        style: pw.TextStyle(
            fontSize: 8, fontWeight: pw.FontWeight.bold, color: _grey));
  }

  // ── TABLES ─────────────────────────────────────────────────────────────
  static pw.Widget _buildPlatformTable(double platformAmount) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      headerStyle: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: _primary),
      headerCellDecoration: const pw.BoxDecoration(),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellHeight: 30,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
      },
      headers: ['Item Description', 'HSN/SAC', 'Per Unit Price', 'Qty', 'Total'],
      data: [
        [
          'Convenience Charges / Platform Fee',
          _hsnCode,
          _fmt(platformAmount),
          '1',
          _fmt(platformAmount),
        ]
      ],
    );
  }

  static pw.Widget _buildProviderTable(BookingModel booking) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      headerStyle: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: _primary),
      headerCellDecoration: const pw.BoxDecoration(),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellHeight: 30,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.center,
        4: pw.Alignment.centerRight,
      },
      headers: ['Service', 'HSN/SAC', 'Per Unit Price', 'Qty', 'Total'],
      data: booking.services.map((s) {
        final double unitPrice = s.quantity > 0 ? s.price / s.quantity : s.price;
        final double providerUnitPrice = unitPrice * 0.80;
        final double providerTotal = s.price * 0.80;
        return [
          s.serviceName,
          _hsnCode,
          _fmt(providerUnitPrice),
          s.quantity.toString(),
          _fmt(providerTotal),
        ];
      }).toList(),
    );
  }

  // ── AMOUNT SUMMARY ─────────────────────────────────────────────────────
  static pw.Widget _buildAmountSummary(
      List<_SummaryRow> rows, double total) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 290,
        child: pw.Column(
          children: [
            ...rows.map((r) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(r.label,
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.SizedBox(
                        width: 90,
                        child: pw.Text(_fmt(r.amount),
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  ),
                )),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: pw.BoxDecoration(
                color: _primaryLight,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: _primary, width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL',
                      style: pw.TextStyle(
                          fontSize: 13, fontWeight: pw.FontWeight.bold)),
                  pw.Text(_fmt(total),
                      style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: _primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _amountInWords(double amount) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 290,
        child: pw.Padding(
          padding: const pw.EdgeInsets.only(top: 4),
          child: pw.Text(
            'Amount in words: ${_numberToWords(amount.round())} Rupees Only',
            style: pw.TextStyle(
                fontSize: 7,
                fontStyle: pw.FontStyle.italic,
                color: _grey),
          ),
        ),
      ),
    );
  }

  // ── BANK DETAILS ───────────────────────────────────────────────────────
  static pw.Widget _buildBankDetails() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              borderRadius: pw.BorderRadius.circular(4),
              border: pw.Border.all(color: _divider),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BANK DETAILS',
                    style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: _grey)),
                pw.SizedBox(height: 5),
                _bankRow('Beneficiary Name', _beneficiaryName),
                _bankRow('Bank Name', _bankName),
                _bankRow('Account No', _accountNo),
                _bankRow('IFSC Code', _ifsc),
                _bankRow('Branch', _branch),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Column(
          children: [
            pw.SizedBox(height: 30),
            pw.Container(width: 120, height: 0.5, color: _dark),
            pw.SizedBox(height: 4),
            pw.Text('Authorized Signatory',
                style: const pw.TextStyle(fontSize: 8, color: _grey)),
            pw.Text(_companyName,
                style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    color: _grey)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _bankRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
              width: 90,
              child: pw.Text('$label:',
                  style: const pw.TextStyle(fontSize: 7, color: _grey))),
          pw.Expanded(
            child: pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 7, fontWeight: pw.FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── FOOTER ─────────────────────────────────────────────────────────────
  static pw.Widget _buildFooter(String message) {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(message,
              style: pw.TextStyle(
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                  color: _primary)),
          pw.SizedBox(height: 4),
          pw.Text(
              'This is a computer-generated document. No signature required.',
              style: const pw.TextStyle(fontSize: 7, color: _grey)),
        ],
      ),
    );
  }

  // ── Number to words (Indian system) ────────────────────────────────────
  static String _numberToWords(int n) {
    if (n == 0) return 'Zero';
    final ones = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
      'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
      'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    ];
    final tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy',
      'Eighty', 'Ninety'
    ];
    String w = '';
    if (n >= 10000000) {
      w += '${ones[n ~/ 10000000]} Crore ';
      n %= 10000000;
    }
    if (n >= 100000) {
      w += '${ones[n ~/ 100000]} Lakh ';
      n %= 100000;
    }
    if (n >= 1000) {
      final t = n ~/ 1000;
      if (t < 20) {
        w += '${ones[t]} Thousand ';
      } else {
        w += '${tens[t ~/ 10]}${t % 10 > 0 ? ' ${ones[t % 10]}' : ''} Thousand ';
      }
      n %= 1000;
    }
    if (n >= 100) {
      w += '${ones[n ~/ 100]} Hundred ';
      n %= 100;
    }
    if (n > 0) {
      if (n < 20) {
        w += ones[n];
      } else {
        w += tens[n ~/ 10];
        if (n % 10 > 0) w += ' ${ones[n % 10]}';
      }
    }
    return w.trim();
  }
}

class _SummaryRow {
  final String label;
  final double amount;
  _SummaryRow(this.label, this.amount);
}
