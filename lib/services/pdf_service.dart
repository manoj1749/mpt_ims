import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/purchase_order.dart';
import '../models/supplier.dart';

class PDFService {
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
    final pdf = pw.Document();

    // Load font that supports Unicode characters
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

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
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with company details
              _buildHeader(companyName, companyAddress, companyGSTN, companyMobile, companyEmail, logoImage, font, fontBold),
              
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
              
              pw.Spacer(),
              
              // Terms and conditions
              _buildTermsAndConditions(supplier, font, fontBold),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String companyName, String companyAddress, 
      String gstNo, String mobile, String email, pw.MemoryImage logoImage, pw.Font font, pw.Font fontBold) {
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

  static pw.Widget _buildPOHeader(PurchaseOrder purchaseOrder, pw.Font font, pw.Font fontBold) {
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
                      pw.Text(purchaseOrder.poNo, style: pw.TextStyle(font: font)),
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
                      pw.Text(purchaseOrder.poDate, style: pw.TextStyle(font: font)),
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

  static pw.Widget _buildSupplierDetails(Supplier supplier, PurchaseOrder purchaseOrder, pw.Font font, pw.Font fontBold) {
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
                          pw.Text(supplier.address1, style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.address2.isNotEmpty)
                          pw.Text(supplier.address2, style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.address3.isNotEmpty)
                          pw.Text(supplier.address3, style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.address4.isNotEmpty)
                          pw.Text(supplier.address4, style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.state.isNotEmpty)
                          pw.Text('${supplier.state} - ${supplier.stateCode}', 
                            style: pw.TextStyle(fontSize: 10, font: font)),
                        pw.SizedBox(height: 4),
                        if (supplier.gstNo.isNotEmpty)
                          pw.Text('GST: ${supplier.gstNo}', style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.phone.isNotEmpty)
                          pw.Text('Phone: ${supplier.phone}', style: pw.TextStyle(fontSize: 10, font: font)),
                        if (supplier.email.isNotEmpty)
                          pw.Text('Email: ${supplier.email}', style: pw.TextStyle(fontSize: 10, font: font)),
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

  static pw.Widget _buildItemsTable(PurchaseOrder purchaseOrder, pw.Font font, pw.Font fontBold) {
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
                _buildTableCell('SR NO:', width: 40, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('CAT NO:', width: 80, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('DESCRIPTION:', width: 200, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('QTY:', width: 50, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('UNIT:', width: 50, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('COST/\nUNIT:', width: 60, isHeader: true, font: font, fontBold: fontBold),
                _buildTableCell('TOTAL\nCOST:', width: 60, isHeader: true, font: font, fontBold: fontBold),
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
                  _buildTableCell((index + 1).toString(), width: 40, font: font, fontBold: fontBold),
                  _buildTableCell(item.materialCode, width: 80, font: font, fontBold: fontBold),
                  _buildTableCell(item.materialDescription, width: 200, font: font, fontBold: fontBold),
                  _buildTableCell(item.quantity, width: 50, font: font, fontBold: fontBold),
                  _buildTableCell(item.unit, width: 50, font: font, fontBold: fontBold),
                  _buildTableCell('Rs.${item.costPerUnit}', width: 60, font: font, fontBold: fontBold),
                  _buildTableCell('Rs.${item.totalCost}', width: 60, font: font, fontBold: fontBold),
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
                  _buildTableCell('', width: 40, font: font, fontBold: fontBold),
                  _buildTableCell('', width: 80, font: font, fontBold: fontBold),
                  _buildTableCell('', width: 200, font: font, fontBold: fontBold),
                  _buildTableCell('', width: 50, font: font, fontBold: fontBold),
                  _buildTableCell('', width: 50, font: font, fontBold: fontBold),
                  _buildTableCell('', width: 60, font: font, fontBold: fontBold),
                  _buildTableCell('', width: 60, font: font, fontBold: fontBold),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {double? width, bool isHeader = false, required pw.Font font, required pw.Font fontBold}) {
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
      ),
    );
  }

  static pw.Widget _buildTotalsSection(PurchaseOrder purchaseOrder, pw.Font font, pw.Font fontBold) {
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
              _buildTotalRow('TOTAL:', 'Rs.${purchaseOrder.total.toStringAsFixed(2)}', font: font, fontBold: fontBold),
              if (purchaseOrder.igst > 0)
                _buildTotalRow('IGST @ ${_getIGSTPercentage(purchaseOrder)}%:', 
                  'Rs.${purchaseOrder.igst.toStringAsFixed(2)}', font: font, fontBold: fontBold),
              if (purchaseOrder.cgst > 0)
                _buildTotalRow('CGST @ ${_getCGSTPercentage(purchaseOrder)}%:', 
                  'Rs.${purchaseOrder.cgst.toStringAsFixed(2)}', font: font, fontBold: fontBold),
              if (purchaseOrder.sgst > 0)
                _buildTotalRow('SGST @ ${_getSGSTPercentage(purchaseOrder)}%:', 
                  'Rs.${purchaseOrder.sgst.toStringAsFixed(2)}', font: font, fontBold: fontBold),
              _buildTotalRow('GRAND TOTAL:', 'Rs.${purchaseOrder.grandTotal.toStringAsFixed(2)}', 
                isGrandTotal: true, font: font, fontBold: fontBold),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalRow(String label, String amount, {bool isGrandTotal = false, required pw.Font font, required pw.Font fontBold}) {
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
      return ((purchaseOrder.igst / purchaseOrder.total) * 100).toStringAsFixed(0);
    }
    return '0';
  }

  static String _getCGSTPercentage(PurchaseOrder purchaseOrder) {
    if (purchaseOrder.total > 0) {
      return ((purchaseOrder.cgst / purchaseOrder.total) * 100).toStringAsFixed(0);
    }
    return '0';
  }

  static String _getSGSTPercentage(PurchaseOrder purchaseOrder) {
    if (purchaseOrder.total > 0) {
      return ((purchaseOrder.sgst / purchaseOrder.total) * 100).toStringAsFixed(0);
    }
    return '0';
  }

  static pw.Widget _buildTermsAndConditions(Supplier supplier, pw.Font font, pw.Font fontBold) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Terms & Conditions',
            style: pw.TextStyle(
              fontSize: 12,
              font: fontBold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            '• Payment Terms: ${supplier.paymentTerms.isNotEmpty ? supplier.paymentTerms : "As per agreement"}',
            style: pw.TextStyle(fontSize: 9, font: font),
          ),
          pw.Text(
            '• Delivery: As per delivery requirements mentioned above',
            style: pw.TextStyle(fontSize: 9, font: font),
          ),
          pw.Text(
            '• Quality: Materials should meet the specified quality standards',
            style: pw.TextStyle(fontSize: 9, font: font),
          ),
          pw.Text(
            '• Returns: Defective materials will be returned at supplier\'s cost',
            style: pw.TextStyle(fontSize: 9, font: font),
          ),
        ],
      ),
    );
  }

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
      
      // Get accessible directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS || Platform.isMacOS) {
        // Use Documents directory which is always accessible
        directory = await getApplicationDocumentsDirectory();
      } else {
        // For other platforms, try downloads first, fallback to documents
        try {
          directory = await getDownloadsDirectory();
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
        }
      }
      
      if (directory != null) {
        final fileName = 'PurchaseOrder_${purchaseOrder.poNo}.pdf';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pdfData);
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to save PDF: $e');
    }
  }
}