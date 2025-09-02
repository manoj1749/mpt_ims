// ignore_for_file: avoid_print

import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/purchase_order.dart';
import '../models/delivery_challan.dart';
import '../models/supplier.dart';

class PDFService {
  static Future<pw.Document> _setupPdfDocument({
    required pw.Font font,
    required pw.Font fontBold,
  }) async {
    return pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: fontBold,
      ),
    );
  }

  static PdfPageFormat _getPageFormat() {
    return PdfPageFormat.a4.copyWith(
      marginTop: 15.0,
      marginBottom: 15.0,
      marginLeft: 15.0,
      marginRight: 15.0,
    );
  }
  // Company configuration - can be modified as needed
  static const _companyConfig = {
    'name': 'Aimant Industries',
    'address': '''SF.NO.215, ORATTUKUPPAI,
ORATTUKUPPAI, Chettipalayam,
Coimbatore, Tamil Nadu - 641201''',
    'gstn': '33ACKFA4542P1Z3',
    'mobile': '+91 97913 66775',
    'email': 'info@aimantindustries.com',
  };

  static Future<Uint8List> generatePurchaseOrderPDF(
    PurchaseOrder purchaseOrder,
    Supplier supplier,
  ) async {
    // Load font that supports Unicode characters
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    // Initialize PDF document with custom theme
    final pdf = await _setupPdfDocument(font: font, fontBold: fontBold);

    // Load company logo
    final logoData = await rootBundle.load('assets/logo.jpeg');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Company information (configurable)
    final companyName = _companyConfig['name']!;
    final companyAddress = _companyConfig['address']!;
    final companyGSTN = _companyConfig['gstn']!;
    final companyMobile = _companyConfig['mobile']!;
    final companyEmail = _companyConfig['email']!;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: _getPageFormat(),
        maxPages: 2,
        build: (pw.Context context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with company details
              _buildHeader(companyName, companyAddress, companyGSTN,
                  companyMobile, companyEmail, logoImage, font, fontBold),

              pw.SizedBox(height: 20),

              // Purchase Order title and details
              _buildPOHeader(purchaseOrder, font, fontBold),

              pw.SizedBox(height: 20),

              // Supplier details section
              _buildSupplierDetails(supplier, purchaseOrder, font, fontBold),

              pw.SizedBox(height: 20),

              // Items table
              _buildItemsTable(purchaseOrder, font, fontBold),

              pw.SizedBox(height: 20),

              // Totals section
              _buildTotalsSection(purchaseOrder, font, fontBold),

              pw.SizedBox(height: 20),

              // Terms and conditions
              // _buildTermsAndConditions(supplier, font, fontBold),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
      String companyName,
      String companyAddress,
      String gstNo,
      String mobile,
      String email,
      pw.MemoryImage logoImage,
      pw.Font font,
      pw.Font fontBold) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    fontSize: 18,
                    font: fontBold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  companyAddress,
                  style: pw.TextStyle(fontSize: 10, font: font),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'GSTN No: $gstNo',
                  style: pw.TextStyle(fontSize: 10, font: font),
                ),
                pw.Text(
                  'Mobile No : $mobile',
                  style: pw.TextStyle(fontSize: 10, font: font),
                ),
                pw.Text(
                  'E-Mail : $email',
                  style: pw.TextStyle(fontSize: 10, font: font),
                ),
              ],
            ),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              height: 80,
              child: pw.Center(
                child: pw.Image(
                  logoImage,
                  height: 70,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPOHeader(
      PurchaseOrder purchaseOrder, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Purchase Order',
                    style: pw.TextStyle(
                      fontSize: 16,
                      font: fontBold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.Container(
            width: 200,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: PdfColors.black, width: 1),
              ),
            ),
            child: pw.Column(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'PO NO:',
                        style: pw.TextStyle(font: fontBold),
                      ),
                      pw.Text(purchaseOrder.poNo,
                          style: pw.TextStyle(font: font)),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'PO DATE:',
                        style: pw.TextStyle(font: fontBold),
                      ),
                      pw.Text(purchaseOrder.poDate,
                          style: pw.TextStyle(font: font)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSupplierDetails(Supplier supplier,
      PurchaseOrder purchaseOrder, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Supplier Details
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  right: pw.BorderSide(color: PdfColors.black, width: 1),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                      ),
                    ),
                    child: pw.Text(
                      'SUPPLIER DETAILS',
                      style: pw.TextStyle(font: fontBold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          supplier.name,
                          style: pw.TextStyle(
                            fontSize: 12,
                            font: fontBold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        if (supplier.address1.isNotEmpty)
                          pw.Text(supplier.address1,
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.address2.isNotEmpty)
                          pw.Text(supplier.address2,
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.address3.isNotEmpty)
                          pw.Text(supplier.address3,
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.address4.isNotEmpty)
                          pw.Text(supplier.address4,
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.state.isNotEmpty)
                          pw.Text('${supplier.state} - ${supplier.stateCode}',
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        pw.SizedBox(height: 4),
                        if (supplier.gstNo.isNotEmpty)
                          pw.Text('GST: ${supplier.gstNo}',
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.phone.isNotEmpty)
                          pw.Text('Phone: ${supplier.phone}',
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.email.isNotEmpty)
                          pw.Text('Email: ${supplier.email}',
                              style: pw.TextStyle(fontSize: 10, font: font)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Purchase Order Details
          pw.Container(
            width: 200,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Text(
                    'PURCHASE ORDER DETAILS',
                    style: pw.TextStyle(font: fontBold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (supplier.paymentTerms.isNotEmpty) ...[
                        pw.Text(
                          'Payment Terms: ${supplier.paymentTerms}',
                          style: pw.TextStyle(fontSize: 10, font: font),
                        ),
                        pw.SizedBox(height: 4),
                      ],
                      if (purchaseOrder.transport.isNotEmpty) ...[
                        pw.Text(
                          'Transport: ${purchaseOrder.transport}',
                          style: pw.TextStyle(fontSize: 10, font: font),
                        ),
                        pw.SizedBox(height: 4),
                      ],
                      if (purchaseOrder.deliveryRequirements.isNotEmpty) ...[
                        pw.Text(
                          'Delivery Requirements:',
                          style: pw.TextStyle(
                            fontSize: 10,
                            font: fontBold,
                          ),
                        ),
                        pw.Text(
                          purchaseOrder.deliveryRequirements,
                          style: pw.TextStyle(fontSize: 10, font: font),
                        ),
                      ],
                      if (purchaseOrder.formattedBoardNo.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Board No: ${purchaseOrder.formattedBoardNo}',
                          style: pw.TextStyle(fontSize: 10, font: font),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(
      PurchaseOrder purchaseOrder, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        children: [
          // Table header
          pw.Container(
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 1),
              ),
            ),
            child: pw.Row(
              children: [
                _buildTableCell('SR NO:',
                    width: 40, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('CAT NO:',
                    width: 80, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('DESCRIPTION:',
                    width: 200, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('QTY:',
                    width: 50, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('UNIT:',
                    width: 50, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('COST/\nUNIT:',
                    width: 60, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('TOTAL\nCOST:',
                    width: 60, isHeader: true, font: font, fontBold: fontBold),
              ],
            ),
          ),
          // Table rows
          ...purchaseOrder.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
                ),
              ),
              child: pw.Row(
                children: [
                  _buildTableCell((index + 1).toString(),
                      width: 40, font: font, fontBold: fontBold),
                  _buildTableCell(item.materialCode,
                      width: 80, font: font, fontBold: fontBold),
                  _buildTableCell(item.materialDescription,
                      width: 200, font: font, fontBold: fontBold),
                  _buildTableCell(item.quantity,
                      width: 50, font: font, fontBold: fontBold),
                  _buildTableCell(item.unit,
                      width: 50, font: font, fontBold: fontBold),
                  _buildTableCell('Rs.${item.costPerUnit}',
                      width: 60, font: font, fontBold: fontBold),
                  _buildTableCell('Rs.${item.totalCost}',
                      width: 60, font: font, fontBold: fontBold),
                ],
              ),
            );
          }).toList(),
          // Empty rows to fill the table
          ...List.generate(10 - purchaseOrder.items.length, (index) {
            return pw.Container(
              height: 20,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
                ),
              ),
              child: pw.Row(
                children: [
                  _buildTableCell('',
                      width: 40, font: font, fontBold: fontBold),
                  _buildTableCell('',
                      width: 80, font: font, fontBold: fontBold),
                  _buildTableCell('',
                      width: 200, font: font, fontBold: fontBold),
                  _buildTableCell('',
                      width: 50, font: font, fontBold: fontBold),
                  _buildTableCell('',
                      width: 50, font: font, fontBold: fontBold),
                  _buildTableCell('',
                      width: 60, font: font, fontBold: fontBold),
                  _buildTableCell('',
                      width: 60, font: font, fontBold: fontBold),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text,
      {double? width,
      bool isHeader = false,
      required pw.Font font,
      required pw.Font fontBold}) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.all(4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          right: pw.BorderSide(color: PdfColors.black, width: 0.5),
        ),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          font: isHeader ? fontBold : font,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
        maxLines: isHeader ? 2 : 3, // Allow multiple lines for text wrapping
        overflow:
            pw.TextOverflow.visible, // Allow text to wrap instead of clipping
      ),
    );
  }

  static pw.Widget _buildTotalsSection(
      PurchaseOrder purchaseOrder, pw.Font font, pw.Font fontBold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 200,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Column(
            children: [
              _buildTotalRow(
                  'TOTAL:', 'Rs.${purchaseOrder.total.toStringAsFixed(2)}',
                  font: font, fontBold: fontBold),
              if (purchaseOrder.igst > 0)
                _buildTotalRow('IGST @ ${_getIGSTPercentage(purchaseOrder)}%:',
                    'Rs.${purchaseOrder.igst.toStringAsFixed(2)}',
                    font: font, fontBold: fontBold),
              if (purchaseOrder.cgst > 0)
                _buildTotalRow('CGST @ ${_getCGSTPercentage(purchaseOrder)}%:',
                    'Rs.${purchaseOrder.cgst.toStringAsFixed(2)}',
                    font: font, fontBold: fontBold),
              if (purchaseOrder.sgst > 0)
                _buildTotalRow('SGST @ ${_getSGSTPercentage(purchaseOrder)}%:',
                    'Rs.${purchaseOrder.sgst.toStringAsFixed(2)}',
                    font: font, fontBold: fontBold),
              _buildTotalRow('Total GST:',
                  'Rs.${(purchaseOrder.igst + purchaseOrder.cgst + purchaseOrder.sgst).toStringAsFixed(2)}',
                  font: font, fontBold: fontBold),
              _buildTotalRow('Round Off:',
                  'Rs.${((purchaseOrder.igst + purchaseOrder.cgst + purchaseOrder.sgst).ceil() - (purchaseOrder.igst + purchaseOrder.cgst + purchaseOrder.sgst)).toStringAsFixed(2)}',
                  font: font, fontBold: fontBold),
              _buildTotalRow('GRAND TOTAL:',
                  'Rs.${(purchaseOrder.total + (purchaseOrder.igst + purchaseOrder.cgst + purchaseOrder.sgst).ceil()).toStringAsFixed(2)}',
                  isGrandTotal: true, font: font, fontBold: fontBold),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, String amount,
      {bool isGrandTotal = false,
      required pw.Font font,
      required pw.Font fontBold}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: isGrandTotal ? PdfColors.grey300 : null,
        border: const pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              font: isGrandTotal ? fontBold : font,
            ),
          ),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontSize: 10,
              font: isGrandTotal ? fontBold : font,
            ),
          ),
        ],
      ),
    );
  }

  static String _getIGSTPercentage(PurchaseOrder purchaseOrder) {
    if (purchaseOrder.total > 0) {
      return ((purchaseOrder.igst / purchaseOrder.total) * 100)
          .toStringAsFixed(0);
    }
    return '0';
  }

  static String _getCGSTPercentage(PurchaseOrder purchaseOrder) {
    if (purchaseOrder.total > 0) {
      return ((purchaseOrder.cgst / purchaseOrder.total) * 100)
          .toStringAsFixed(0);
    }
    return '0';
  }

  static String _getSGSTPercentage(PurchaseOrder purchaseOrder) {
    if (purchaseOrder.total > 0) {
      return ((purchaseOrder.sgst / purchaseOrder.total) * 100)
          .toStringAsFixed(0);
    }
    return '0';
  }

  // static pw.Widget _buildTermsAndConditions(
  //     Supplier supplier, pw.Font font, pw.Font fontBold) {
  //   return pw.Container(
  //     decoration: pw.BoxDecoration(
  //       border: pw.Border.all(color: PdfColors.black, width: 1),
  //     ),
  //     padding: const pw.EdgeInsets.all(8),
  //     child: pw.Column(
  //       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //       children: [
  //         pw.Text(
  //           'Terms & Conditions',
  //           style: pw.TextStyle(
  //             fontSize: 12,
  //             font: fontBold,
  //           ),
  //         ),
  //         pw.SizedBox(height: 5),
  //         pw.Text(
  //           '• Payment Terms: ${supplier.paymentTerms.isNotEmpty ? supplier.paymentTerms : "As per agreement"}',
  //           style: pw.TextStyle(fontSize: 9, font: font),
  //         ),
  //         pw.Text(
  //           '• Delivery: As per delivery requirements mentioned above',
  //           style: pw.TextStyle(fontSize: 9, font: font),
  //         ),
  //         pw.Text(
  //           '• Quality: Materials should meet the specified quality standards',
  //           style: pw.TextStyle(fontSize: 9, font: font),
  //         ),
  //         pw.Text(
  //           '• Returns: Defective materials will be returned at supplier\'s cost',
  //           style: pw.TextStyle(fontSize: 9, font: font),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  static Future<void> printPurchaseOrder(
    PurchaseOrder purchaseOrder,
    Supplier supplier,
  ) async {
    final pdfData = await generatePurchaseOrderPDF(purchaseOrder, supplier);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: 'PurchaseOrder_${purchaseOrder.poNo}',
    );
  }

  static Future<void> sharePurchaseOrder(
    PurchaseOrder purchaseOrder,
    Supplier supplier,
  ) async {
    final pdfData = await generatePurchaseOrderPDF(purchaseOrder, supplier);

    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'PurchaseOrder_${purchaseOrder.poNo}.pdf',
    );
  }

  static Future<bool> savePurchaseOrder(
    PurchaseOrder purchaseOrder,
    Supplier supplier,
  ) async {
    try {
      // Generate PDF data
      final pdfData = await generatePurchaseOrderPDF(purchaseOrder, supplier);

      // Use saveFile method which works better on macOS
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Purchase Order PDF',
        fileName: 'PurchaseOrder_${purchaseOrder.poNo}.pdf',
        type: FileType.any,
      );

      if (outputFile != null) {
        // Ensure the file has .pdf extension
        if (!outputFile.toLowerCase().endsWith('.pdf')) {
          outputFile = '$outputFile.pdf';
        }

        // Write the PDF file
        final file = File(outputFile);
        await file.writeAsBytes(pdfData);
        return true;
      }
      return false; // User cancelled
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  // Alternative method using accessible directory
  static Future<bool> savePurchaseOrderToDownloads(
    PurchaseOrder purchaseOrder,
    Supplier supplier,
  ) async {
    try {
      // Generate PDF data
      final pdfData = await generatePurchaseOrderPDF(purchaseOrder, supplier);

      // Get accessible directory and create MPT_IMS folder structure
      Directory? baseDirectory;
      if (Platform.isAndroid) {
        baseDirectory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS || Platform.isMacOS) {
        // Use Documents directory which is always accessible
        baseDirectory = await getApplicationDocumentsDirectory();
      } else {
        // For other platforms, try downloads first, fallback to documents
        try {
          baseDirectory = await getDownloadsDirectory();
        } catch (e) {
          baseDirectory = await getApplicationDocumentsDirectory();
        }
      }

      if (baseDirectory != null) {
        // Create MPT_IMS/Purchase_Orders folder structure
        final mptImsDirectory = Directory('${baseDirectory.path}/MPT_IMS');
        final poDirectory = Directory('${mptImsDirectory.path}/Purchase_Orders');
        
        // Create directories if they don't exist
        if (!await mptImsDirectory.exists()) {
          await mptImsDirectory.create(recursive: true);
        }
        if (!await poDirectory.exists()) {
          await poDirectory.create(recursive: true);
        }

        final fileName = 'PurchaseOrder_${purchaseOrder.poNo}.pdf';
        final file = File('${poDirectory.path}/$fileName');
        await file.writeAsBytes(pdfData);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  // ============== DELIVERY CHALLAN PDF METHODS ==============

  static Future<Uint8List> generateInvoicePDF(
    DeliveryChallan deliveryChallan,
    Supplier supplier, {
    List<dynamic>? materials,
  }) async {
    // Load font that supports Unicode characters
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    // Initialize PDF document with custom theme
    final pdf = await _setupPdfDocument(font: font, fontBold: fontBold);

    // Load company logo
    final logoData = await rootBundle.load('assets/logo.jpeg');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Company information (configurable)
    final companyName = _companyConfig['name']!;
    final companyAddress = _companyConfig['address']!;
    final companyGSTN = _companyConfig['gstn']!;
    final companyMobile = _companyConfig['mobile']!;
    final companyEmail = _companyConfig['email']!;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: _getPageFormat(),
        // maxPages: 2,
        build: (pw.Context context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with company details
              _buildHeader(companyName, companyAddress, companyGSTN,
                  companyMobile, companyEmail, logoImage, font, fontBold),

              pw.SizedBox(height: 20),

              // Invoice title and details
              _buildInvoiceHeader(deliveryChallan, font, fontBold),

              pw.SizedBox(height: 20),

              // Supplier details section
              _buildSupplierDetailsForInvoice(
                  supplier, deliveryChallan, font, fontBold),

              pw.SizedBox(height: 20),

              // Items table
              _buildDCItemsTable(
                  deliveryChallan, font, fontBold, materials, supplier),

              pw.SizedBox(height: 20),

              // Totals section
              _buildDCTotalsSection(
                  deliveryChallan, font, fontBold, materials, supplier),

              pw.SizedBox(height: 20),

              // Notes section (if any)
              if (deliveryChallan.note != null &&
                  deliveryChallan.note!.isNotEmpty)
                _buildNotesSection(deliveryChallan.note!, font, fontBold),

              pw.SizedBox(height: 20),

              // Terms and conditions
              // _buildInvoiceTermsAndConditions(
              //     supplier, deliveryChallan, font, fontBold),
            ],
          ),
        ],
      ),

    );

    return pdf.save();
  }

  static Future<Uint8List> generateDeliveryChallanPDF(
    DeliveryChallan deliveryChallan,
    Supplier supplier, {
    List<dynamic>?
        materials, // Optional material master data for HSN codes and rates
  }) async {
    // Load font that supports Unicode characters
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    // Initialize PDF document with custom theme
    final pdf = await _setupPdfDocument(font: font, fontBold: fontBold);

    // Load company logo
    final logoData = await rootBundle.load('assets/logo.jpeg');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Company information (configurable)
    final companyName = _companyConfig['name']!;
    final companyAddress = _companyConfig['address']!;
    final companyGSTN = _companyConfig['gstn']!;
    final companyMobile = _companyConfig['mobile']!;
    final companyEmail = _companyConfig['email']!;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: _getPageFormat(),
        maxPages: 2,
        build: (pw.Context context) => [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with company details
              _buildHeader(companyName, companyAddress, companyGSTN,
                  companyMobile, companyEmail, logoImage, font, fontBold),

              pw.SizedBox(height: 20),

              // Delivery Challan title and details
              _buildDCHeader(deliveryChallan, font, fontBold),

              pw.SizedBox(height: 20),

              // Supplier details section
              _buildSupplierDetailsForDC(
                  supplier, deliveryChallan, font, fontBold),

              pw.SizedBox(height: 20),

              // Items table
              _buildDCItemsTable(
                  deliveryChallan, font, fontBold, materials, supplier),

              pw.SizedBox(height: 20),

              // Totals section
              _buildDCTotalsSection(
                  deliveryChallan, font, fontBold, materials, supplier),

              pw.SizedBox(height: 20),

              // Notes section (if any)
              if (deliveryChallan.note != null &&
                  deliveryChallan.note!.isNotEmpty)
                _buildNotesSection(deliveryChallan.note!, font, fontBold),

              pw.SizedBox(height: 20),

              // Terms and conditions
              // _buildDCTermsAndConditions(
              //     supplier, deliveryChallan, font, fontBold),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInvoiceHeader(
      DeliveryChallan deliveryChallan, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Tax Invoice',
                    style: pw.TextStyle(
                      fontSize: 16,
                      font: fontBold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.Container(
            width: 200,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: PdfColors.black, width: 1),
              ),
            ),
            child: pw.Column(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'INVOICE DATE:',
                        style: pw.TextStyle(font: fontBold),
                      ),
                      pw.Text(deliveryChallan.dcDate,
                          style: pw.TextStyle(font: font)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDCHeader(
      DeliveryChallan deliveryChallan, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Delivery Challan',
                    style: pw.TextStyle(
                      fontSize: 16,
                      font: fontBold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.Container(
            width: 200,
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                left: pw.BorderSide(color: PdfColors.black, width: 1),
              ),
            ),
            child: pw.Column(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'DC NO:',
                        style: pw.TextStyle(font: fontBold),
                      ),
                      pw.Text(deliveryChallan.dcNo,
                          style: pw.TextStyle(font: font)),
                    ],
                  ),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'DC DATE:',
                        style: pw.TextStyle(font: fontBold),
                      ),
                      pw.Text(deliveryChallan.dcDate,
                          style: pw.TextStyle(font: font)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSupplierDetailsForInvoice(Supplier supplier,
      DeliveryChallan deliveryChallan, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Supplier Details
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  right: pw.BorderSide(color: PdfColors.black, width: 1),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                      ),
                    ),
                    child: pw.Text(
                      'BILL TO',
                      style: pw.TextStyle(font: fontBold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          supplier.name,
                          style: pw.TextStyle(
                            fontSize: 12,
                            font: fontBold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        if (supplier.address1.isNotEmpty)
                          pw.Text(supplier.address1,
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.address2.isNotEmpty)
                          pw.Text(supplier.address2,
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.address3.isNotEmpty)
                          pw.Text(supplier.address3,
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.address4.isNotEmpty)
                          pw.Text(supplier.address4,
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.state.isNotEmpty)
                          pw.Text('${supplier.state} - ${supplier.stateCode}',
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        pw.SizedBox(height: 4),
                        if (supplier.gstNo.isNotEmpty)
                          pw.Text('GST: ${supplier.gstNo}',
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.phone.isNotEmpty)
                          pw.Text('Phone: ${supplier.phone}',
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.email.isNotEmpty)
                          pw.Text('Email: ${supplier.email}',
                              style: pw.TextStyle(fontSize: 10, font: font)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Invoice Details
          pw.Container(
            width: 200,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Text(
                    'INVOICE DETAILS',
                    style: pw.TextStyle(font: fontBold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (supplier.paymentTerms.isNotEmpty) ...[
                        pw.Text(
                          'Payment Terms: ${supplier.paymentTerms}',
                          style: pw.TextStyle(fontSize: 10, font: font),
                        ),
                        pw.SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSupplierDetailsForDC(Supplier supplier,
      DeliveryChallan deliveryChallan, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Supplier Details
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  right: pw.BorderSide(color: PdfColors.black, width: 1),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey300,
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                      ),
                    ),
                    child: pw.Text(
                      'VENDOR DETAILS',
                      style: pw.TextStyle(font: fontBold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          supplier.name,
                          style: pw.TextStyle(
                            fontSize: 12,
                            font: fontBold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        if (supplier.address1.isNotEmpty)
                          pw.Text(supplier.address1,
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.address2.isNotEmpty)
                          pw.Text(supplier.address2,
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.address3.isNotEmpty)
                          pw.Text(supplier.address3,
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.address4.isNotEmpty)
                          pw.Text(supplier.address4,
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.state.isNotEmpty)
                          pw.Text('${supplier.state} - ${supplier.stateCode}',
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        pw.SizedBox(height: 4),
                        if (supplier.gstNo.isNotEmpty)
                          pw.Text('GST: ${supplier.gstNo}',
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.phone.isNotEmpty)
                          pw.Text('Phone: ${supplier.phone}',
                              style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.email.isNotEmpty)
                          pw.Text('Email: ${supplier.email}',
                              style: pw.TextStyle(fontSize: 10, font: font)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Delivery Challan Details
          pw.Container(
            width: 200,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                  ),
                  child: pw.Text(
                    'DELIVERY CHALLAN DETAILS',
                    style: pw.TextStyle(font: fontBold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Returnable: ${deliveryChallan.isReturnable ? "Yes" : "No"}',
                        style: pw.TextStyle(fontSize: 10, font: font),
                      ),
                      if (supplier.paymentTerms.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Payment Terms: ${supplier.paymentTerms}',
                          style: pw.TextStyle(fontSize: 10, font: font),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDCItemsTable(
      DeliveryChallan deliveryChallan,
      pw.Font font,
      pw.Font fontBold,
      List<dynamic>? materials,
      Supplier supplier) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        children: [
          // Table header
          pw.Container(
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 1),
              ),
            ),
            child: pw.Row(
              children: [
                _buildTableCell('SR NO:',
                    width: 35, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('MATERIAL CODE:',
                    width: 95, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('DESCRIPTION:',
                    width: 120, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('QTY:',
                    width: 45, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('UNIT:',
                    width: 45, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('RATE:',
                    width: 65, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('VALUE:',
                    width: 65, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('JOB NO:',
                    width: 70, isHeader: true, font: font, fontBold: fontBold),
              ],
            ),
          ),
          // Table rows
          ...deliveryChallan.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            // Find material data for rate and value calculation
            String rate = '0.00';
            String value = '0.00';
            double rateValue = 0.0;

            if (materials != null) {
              try {
                // Find the material by part number (primary) or description (fallback)
                dynamic materialData;
                try {
                  materialData = materials.firstWhere(
                    (m) => m.partNo == item.materialCode,
                  );
                } catch (e) {
                  materialData = null;
                }

                // If not found by part number, try by description
                if (materialData == null) {
                  try {
                    materialData = materials.firstWhere(
                      (m) => m.description == item.materialDescription,
                    );
                  } catch (e) {
                    materialData = null;
                  }
                }

                if (materialData != null) {
                  print(
                      'Found material: ${materialData.partNo} - ${materialData.description}');
                  print(
                      'Looking for rates from DC vendor: ${supplier.name} (${supplier.vendorCode})');

                  // Priority 1: Get rate from the specific vendor for this DC
                  if (materialData.vendorRates != null &&
                      materialData.vendorRates.isNotEmpty) {
                    // Look for the specific vendor from the DC
                    var dcVendorRate;
                    try {
                      dcVendorRate = materialData.vendorRates.firstWhere(
                        (vr) =>
                            (vr.vendorId == supplier.name ||
                                vr.vendorId == supplier.vendorCode) &&
                            vr.purchaseRate != null &&
                            vr.purchaseRate.isNotEmpty &&
                            double.tryParse(vr.purchaseRate) != null &&
                            double.tryParse(vr.purchaseRate)! > 0,
                      );
                    } catch (e) {
                      dcVendorRate = null;
                    }

                    if (dcVendorRate != null) {
                      rateValue =
                          double.tryParse(dcVendorRate.purchaseRate) ?? 0.0;
                      print(
                          'Using DC vendor (${supplier.name}) purchase rate: $rateValue');
                    } else {
                      print(
                          'No rate found for DC vendor ${supplier.name}, checking other options...');

                      // Priority 2: Try preferred vendor if DC vendor rate not found
                      var preferredVendor;
                      try {
                        preferredVendor = materialData.vendorRates.firstWhere(
                          (vr) =>
                              vr.isPreferred == true &&
                              vr.purchaseRate != null &&
                              vr.purchaseRate.isNotEmpty &&
                              double.tryParse(vr.purchaseRate) != null &&
                              double.tryParse(vr.purchaseRate)! > 0,
                        );
                      } catch (e) {
                        preferredVendor = null;
                      }

                      if (preferredVendor != null) {
                        rateValue =
                            double.tryParse(preferredVendor.purchaseRate) ??
                                0.0;
                        print(
                            'Using preferred vendor rate: $rateValue from ${preferredVendor.vendorId}');
                      } else {
                        // Priority 3: Get any valid purchase rate from vendor rates
                        for (var vendorRate in materialData.vendorRates) {
                          if (vendorRate.purchaseRate != null &&
                              vendorRate.purchaseRate.isNotEmpty) {
                            final purchaseRate =
                                double.tryParse(vendorRate.purchaseRate) ?? 0.0;
                            if (purchaseRate > 0) {
                              rateValue = purchaseRate;
                              print(
                                  'Using fallback vendor purchase rate: $rateValue from vendor: ${vendorRate.vendorId}');
                              break;
                            }
                          }
                        }
                      }
                    }
                  }

                  // Priority 4: Fallback to sale rate if no vendor rate found
                  if (rateValue == 0.0 &&
                      materialData.saleRate != null &&
                      materialData.saleRate.isNotEmpty) {
                    rateValue = double.tryParse(materialData.saleRate) ?? 0.0;
                    print('Using material sale rate: $rateValue');
                  }

                  print('Final rate for ${item.materialCode}: $rateValue');

                  rate = rateValue.toStringAsFixed(2);
                  final totalValue = rateValue * item.quantity;
                  value = totalValue.toStringAsFixed(2);
                } else {
                  print(
                      'Material not found for: ${item.materialCode} - ${item.materialDescription}');
                }
              } catch (e) {
                print('Error finding material rate: $e');
              }
            }

            return pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
                ),
              ),
              child: pw.Row(
                children: [
                  _buildTableCell((index + 1).toString(),
                      width: 35, font: font, fontBold: fontBold),
                  _buildTableCell(item.materialCode,
                      width: 95, font: font, fontBold: fontBold),
                  _buildTableCell(item.materialDescription,
                      width: 120, font: font, fontBold: fontBold),
                  _buildTableCell(item.quantity.toString(),
                      width: 45, font: font, fontBold: fontBold),
                  _buildTableCell(item.unit,
                      width: 45, font: font, fontBold: fontBold),
                  _buildTableCell('Rs.$rate',
                      width: 65, font: font, fontBold: fontBold),
                  _buildTableCell('Rs.$value',
                      width: 65, font: font, fontBold: fontBold),
                  _buildTableCell(item.jobNo ?? 'General',
                      width: 70, font: font, fontBold: fontBold),
                ],
              ),
            );
          }).toList(),
          // Empty rows to fill the table
          ...List.generate(10 - deliveryChallan.items.length, (index) {
            return pw.Container(
              height: 20,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
                ),
              ),
              child: pw.Row(
                children: [
                  _buildTableCell('',
                      width: 35, font: font, fontBold: fontBold),
                  _buildTableCell('',
                      width: 95, font: font, fontBold: fontBold),
                  _buildTableCell('',
                      width: 120, font: font, fontBold: fontBold),
                  _buildTableCell('',
                      width: 45, font: font, fontBold: fontBold),
                  _buildTableCell('',
                      width: 45, font: font, fontBold: fontBold),
                  _buildTableCell('',
                      width: 65, font: font, fontBold: fontBold),
                  _buildTableCell('',
                      width: 65, font: font, fontBold: fontBold),
                  _buildTableCell('',
                      width: 70, font: font, fontBold: fontBold),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildDCTotalsSection(
      DeliveryChallan deliveryChallan,
      pw.Font font,
      pw.Font fontBold,
      List<dynamic>? materials,
      Supplier supplier) {
    // Calculate totals from items using the same logic as the table
    double total = 0.0;

    // Debug: Enable to troubleshoot rate issues
    bool debug = true;
    if (debug) {
      print('=== DC Totals Debug ===');
      print('Materials available: ${materials?.length ?? 0}');
      print('DC items: ${deliveryChallan.items.length}');
      print('Supplier: ${supplier.name} (IGST: ${supplier.igst}, CGST: ${supplier.cgst}, SGST: ${supplier.sgst})');
    }

    if (materials != null) {
      for (var item in deliveryChallan.items) {
        try {
          // Find the material by part number (primary) or description (fallback)
          dynamic materialData;
          try {
            materialData = materials.firstWhere(
              (m) => m.partNo == item.materialCode,
            );
          } catch (e) {
            materialData = null;
          }

          // If not found by part number, try by description
          if (materialData == null) {
            try {
              materialData = materials.firstWhere(
                (m) => m.description == item.materialDescription,
              );
            } catch (e) {
              materialData = null;
            }
          }

          if (materialData != null) {
            double rateValue = 0.0;
            if (debug) print('Found material: ${materialData.partNo} - ${materialData.description}');

            // Priority 1: Get rate from the specific vendor for this DC
            if (materialData.vendorRates != null &&
                materialData.vendorRates.isNotEmpty) {
              // Look for the specific vendor from the DC
              var dcVendorRate;
              try {
                dcVendorRate = materialData.vendorRates.firstWhere(
                  (vr) =>
                      (vr.vendorId == supplier.name ||
                          vr.vendorId == supplier.vendorCode) &&
                      vr.purchaseRate != null &&
                      vr.purchaseRate.isNotEmpty &&
                      double.tryParse(vr.purchaseRate) != null &&
                      double.tryParse(vr.purchaseRate)! > 0,
                );
              } catch (e) {
                dcVendorRate = null;
              }

              if (dcVendorRate != null) {
                rateValue = double.tryParse(dcVendorRate.purchaseRate) ?? 0.0;
              } else {
                // Priority 2: Try preferred vendor if DC vendor rate not found
                var preferredVendor;
                try {
                  preferredVendor = materialData.vendorRates.firstWhere(
                    (vr) =>
                        vr.isPreferred == true &&
                        vr.purchaseRate != null &&
                        vr.purchaseRate.isNotEmpty &&
                        double.tryParse(vr.purchaseRate) != null &&
                        double.tryParse(vr.purchaseRate)! > 0,
                  );
                } catch (e) {
                  preferredVendor = null;
                }

                if (preferredVendor != null) {
                  rateValue =
                      double.tryParse(preferredVendor.purchaseRate) ?? 0.0;
                } else {
                  // Priority 3: Get any valid purchase rate from vendor rates
                  for (var vendorRate in materialData.vendorRates) {
                    if (vendorRate.purchaseRate != null &&
                        vendorRate.purchaseRate.isNotEmpty) {
                      final purchaseRate =
                          double.tryParse(vendorRate.purchaseRate) ?? 0.0;
                      if (purchaseRate > 0) {
                        rateValue = purchaseRate;
                        break;
                      }
                    }
                  }
                }
              }
            }

            // Priority 4: Fallback to sale rate if no vendor rate found
            if (rateValue == 0.0 &&
                materialData.saleRate != null &&
                materialData.saleRate.isNotEmpty) {
              rateValue = double.tryParse(materialData.saleRate) ?? 0.0;
            }

            total += rateValue * item.quantity;
            
            if (debug) {
              print('${item.materialCode}: Rate=$rateValue x Qty=${item.quantity} = $total');
            }
          } else {
            if (debug) print('Material NOT FOUND: ${item.materialCode} - ${item.materialDescription}');
          }
        } catch (e) {
          if (debug) print('Error processing ${item.materialCode}: $e');
        }
      }
    }

    // Calculate GST using supplier's GST configuration and state
    double parseGstRate(String? value) {
      if (value == null || value.isEmpty) return 0.0;
      value = value.replaceAll('%', '').trim();
      return double.tryParse(value) ?? 0.0;
    }

    // Get company state code from GSTN (first two digits)
    final companyStateCode = _companyConfig['gstn']!.substring(0, 2);
    final supplierStateCode = supplier.gstNo.isNotEmpty ? supplier.gstNo.substring(0, 2) : '';
    
    // Calculate GST based on state comparison
    double igst = 0.0;
    double cgst = 0.0;
    double sgst = 0.0;
    
    if (supplierStateCode == companyStateCode) {
      // Same state - apply CGST and SGST
      cgst = total * (parseGstRate(supplier.cgst) / 100);
      sgst = total * (parseGstRate(supplier.sgst) / 100);
    } else {
      // Different state - apply IGST
      igst = total * (parseGstRate(supplier.igst) / 100);
    }

    // Calculate total GST and round off
    final actualTotalGst = igst + cgst + sgst;
    final roundedTotalGst = actualTotalGst.ceil();
    final roundOff = roundedTotalGst - actualTotalGst;

    if (debug) {
      print('=== DC Totals Debug ===');
      print('Subtotal: $total');
      print('IGST: $igst');
      print('CGST: $cgst');
      print('SGST: $sgst');
      print('Total GST (actual): $actualTotalGst');
      print('Total GST (rounded): $roundedTotalGst');
      print('Round Off: $roundOff');
      print('Grand Total: ${total + roundedTotalGst}');
      print('=== End DC Totals Debug ===');
    }

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 200,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Column(
            children: [
              _buildTotalRow('TOTAL:', 'Rs.${total.toStringAsFixed(2)}',
                  font: font, fontBold: fontBold),
              if (igst > 0)
                _buildTotalRow('IGST @ ${parseGstRate(supplier.igst).toStringAsFixed(0)}%:', 'Rs.${igst.toStringAsFixed(2)}',
                    font: font, fontBold: fontBold),
              if (cgst > 0)
                _buildTotalRow('CGST @ ${parseGstRate(supplier.cgst).toStringAsFixed(0)}%:', 'Rs.${cgst.toStringAsFixed(2)}',
                    font: font, fontBold: fontBold),
              if (sgst > 0)
                _buildTotalRow('SGST @ ${parseGstRate(supplier.sgst).toStringAsFixed(0)}%:', 'Rs.${sgst.toStringAsFixed(2)}',
                    font: font, fontBold: fontBold),
              _buildTotalRow('Total GST:', 'Rs.${actualTotalGst.toStringAsFixed(2)}',
                  font: font, fontBold: fontBold),
              _buildTotalRow('Round Off:', 'Rs.${roundOff.toStringAsFixed(2)}',
                  font: font, fontBold: fontBold),
              _buildTotalRow(
                  'GRAND TOTAL:', 'Rs.${(total + roundedTotalGst).toStringAsFixed(2)}',
                  isGrandTotal: true, font: font, fontBold: fontBold),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildNotesSection(
      String note, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      padding: const pw.EdgeInsets.all(8),
      margin: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Notes:',
            style: pw.TextStyle(
              fontSize: 12,
              font: fontBold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            note,
            style: pw.TextStyle(fontSize: 10, font: font),
          ),
        ],
      ),
    );
  }

  // static pw.Widget _buildInvoiceTermsAndConditions(Supplier supplier,
  //     DeliveryChallan deliveryChallan, pw.Font font, pw.Font fontBold) {
  //   return pw.Container(
  //     decoration: pw.BoxDecoration(
  //       border: pw.Border.all(color: PdfColors.black, width: 1),
  //     ),
  //     padding: const pw.EdgeInsets.all(8),
  //     child: pw.Column(
  //       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //       children: [
  //         pw.Text(
  //           'Terms & Conditions',
  //           style: pw.TextStyle(
  //             fontSize: 12,
  //             font: fontBold,
  //           ),
  //         ),
  //         pw.SizedBox(height: 5),
  //         pw.Text(
  //           '• Payment Terms: ${supplier.paymentTerms.isNotEmpty ? supplier.paymentTerms : "As per agreement"}',
  //           style: pw.TextStyle(fontSize: 9, font: font),
  //         ),
  //         pw.Text(
  //           '• Materials delivered as per the specifications mentioned',
  //           style: pw.TextStyle(fontSize: 9, font: font),
  //         ),
  //         pw.Text(
  //           '• Any discrepancy should be reported within 24 hours',
  //           style: pw.TextStyle(fontSize: 9, font: font),
  //         ),
  //         pw.Text(
  //           '• This invoice is subject to terms and conditions of sale',
  //           style: pw.TextStyle(fontSize: 9, font: font),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // static pw.Widget _buildDCTermsAndConditions(Supplier supplier,
  //     DeliveryChallan deliveryChallan, pw.Font font, pw.Font fontBold) {
  //   return pw.Container(
  //     decoration: pw.BoxDecoration(
  //       border: pw.Border.all(color: PdfColors.black, width: 1),
  //     ),
  //     padding: const pw.EdgeInsets.all(8),
  //     child: pw.Column(
  //       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //       children: [
  //         pw.Text(
  //           'Terms & Conditions',
  //           style: pw.TextStyle(
  //             fontSize: 12,
  //             font: fontBold,
  //           ),
  //         ),
  //         pw.SizedBox(height: 5),
  //         pw.Text(
  //           '• This delivery challan is ${deliveryChallan.isReturnable ? "returnable" : "non-returnable"}',
  //           style: pw.TextStyle(fontSize: 9, font: font),
  //         ),
  //         pw.Text(
  //           '• Materials delivered as per the specifications mentioned',
  //           style: pw.TextStyle(fontSize: 9, font: font),
  //         ),
  //         pw.Text(
  //           '• Any discrepancy should be reported within 24 hours',
  //           style: pw.TextStyle(fontSize: 9, font: font),
  //         ),
  //         if (deliveryChallan.isReturnable)
  //           pw.Text(
  //             '• Materials should be returned in original condition',
  //             style: pw.TextStyle(fontSize: 9, font: font),
  //           ),
  //       ],
  //     ),
  //   );
  // }

  static Future<void> printDeliveryChallan(
    DeliveryChallan deliveryChallan,
    Supplier supplier, {
    List<dynamic>? materials,
  }) async {
    final pdfData = await generateDeliveryChallanPDF(deliveryChallan, supplier,
        materials: materials);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: 'DeliveryChallan_${deliveryChallan.dcNo}',
    );
  }

  static Future<void> shareDeliveryChallan(
    DeliveryChallan deliveryChallan,
    Supplier supplier, {
    List<dynamic>? materials,
  }) async {
    final pdfData = await generateDeliveryChallanPDF(deliveryChallan, supplier,
        materials: materials);

    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'DeliveryChallan_${deliveryChallan.dcNo}.pdf',
    );
  }

  static Future<bool> saveDeliveryChallan(
    DeliveryChallan deliveryChallan,
    Supplier supplier, {
    List<dynamic>? materials,
  }) async {
    try {
      // Generate PDF data
      final pdfData = await generateDeliveryChallanPDF(
          deliveryChallan, supplier,
          materials: materials);

      // Use saveFile method which works better on macOS
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Delivery Challan PDF',
        fileName: 'DeliveryChallan_${deliveryChallan.dcNo}.pdf',
        type: FileType.any,
      );

      if (outputFile != null) {
        // Ensure the file has .pdf extension
        if (!outputFile.toLowerCase().endsWith('.pdf')) {
          outputFile = '$outputFile.pdf';
        }

        // Write the PDF file
        final file = File(outputFile);
        await file.writeAsBytes(pdfData);
        return true;
      }
      return false; // User cancelled
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  static Future<bool> saveDeliveryChallanToDownloads(
    DeliveryChallan deliveryChallan,
    Supplier supplier, {
    List<dynamic>? materials,
  }) async {
    try {
      // Generate PDF data
      final pdfData = await generateDeliveryChallanPDF(
          deliveryChallan, supplier,
          materials: materials);

      // Get accessible directory and create MPT_IMS folder structure
      Directory? baseDirectory;
      if (Platform.isAndroid) {
        baseDirectory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS || Platform.isMacOS) {
        // Use Documents directory which is always accessible
        baseDirectory = await getApplicationDocumentsDirectory();
      } else {
        // For other platforms, try downloads first, fallback to documents
        try {
          baseDirectory = await getDownloadsDirectory();
        } catch (e) {
          baseDirectory = await getApplicationDocumentsDirectory();
        }
      }

      if (baseDirectory != null) {
        // Create MPT_IMS/Delivery_Challans folder structure
        final mptImsDirectory = Directory('${baseDirectory.path}/MPT_IMS');
        final dcDirectory = Directory('${mptImsDirectory.path}/Delivery_Challans');
        
        // Create directories if they don't exist
        if (!await mptImsDirectory.exists()) {
          await mptImsDirectory.create(recursive: true);
        }
        if (!await dcDirectory.exists()) {
          await dcDirectory.create(recursive: true);
        }

        final fileName = 'DeliveryChallan_${deliveryChallan.dcNo}.pdf';
        final file = File('${dcDirectory.path}/$fileName');
        await file.writeAsBytes(pdfData);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  // ============== INVOICE PDF METHODS ==============

  static Future<void> printInvoice(
    DeliveryChallan deliveryChallan,
    Supplier supplier, {
    List<dynamic>? materials,
  }) async {
    final pdfData = await generateInvoicePDF(deliveryChallan, supplier,
        materials: materials);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: 'Invoice_${deliveryChallan.dcNo}',
    );
  }

  static Future<void> shareInvoice(
    DeliveryChallan deliveryChallan,
    Supplier supplier, {
    List<dynamic>? materials,
  }) async {
    final pdfData = await generateInvoicePDF(deliveryChallan, supplier,
        materials: materials);

    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'Invoice_${deliveryChallan.dcNo}.pdf',
    );
  }

  static Future<bool> saveInvoice(
    DeliveryChallan deliveryChallan,
    Supplier supplier, {
    List<dynamic>? materials,
  }) async {
    try {
      // Generate PDF data
      final pdfData = await generateInvoicePDF(deliveryChallan, supplier,
          materials: materials);

      // Use saveFile method which works better on macOS
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Invoice PDF',
        fileName: 'Invoice_${deliveryChallan.dcNo}.pdf',
        type: FileType.any,
      );

      if (outputFile != null) {
        // Ensure the file has .pdf extension
        if (!outputFile.toLowerCase().endsWith('.pdf')) {
          outputFile = '$outputFile.pdf';
        }

        // Write the PDF file
        final file = File(outputFile);
        await file.writeAsBytes(pdfData);
        return true;
      }
      return false; // User cancelled
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }

  static Future<bool> saveInvoiceToDownloads(
    DeliveryChallan deliveryChallan,
    Supplier supplier, {
    List<dynamic>? materials,
  }) async {
    try {
      // Generate PDF data
      final pdfData = await generateInvoicePDF(deliveryChallan, supplier,
          materials: materials);

      // Get accessible directory and create MPT_IMS folder structure
      Directory? baseDirectory;
      if (Platform.isAndroid) {
        baseDirectory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS || Platform.isMacOS) {
        // Use Documents directory which is always accessible
        baseDirectory = await getApplicationDocumentsDirectory();
      } else {
        // For other platforms, try downloads first, fallback to documents
        try {
          baseDirectory = await getDownloadsDirectory();
        } catch (e) {
          baseDirectory = await getApplicationDocumentsDirectory();
        }
      }

      if (baseDirectory != null) {
        // Create MPT_IMS/Invoices folder structure
        final mptImsDirectory = Directory('${baseDirectory.path}/MPT_IMS');
        final invoiceDirectory = Directory('${mptImsDirectory.path}/Invoices');
        
        // Create directories if they don't exist
        if (!await mptImsDirectory.exists()) {
          await mptImsDirectory.create(recursive: true);
        }
        if (!await invoiceDirectory.exists()) {
          await invoiceDirectory.create(recursive: true);
        }

        final fileName = 'Invoice_${deliveryChallan.dcNo}.pdf';
        final file = File('${invoiceDirectory.path}/$fileName');
        await file.writeAsBytes(pdfData);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }
}




