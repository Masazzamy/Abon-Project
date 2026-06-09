import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart' as ex;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class EksporHelper {
  /// Export transactions and inventories to Excel (.xlsx) file
  static Future<File?> eksporKeExcel({
    required String namaToko,
    required String periode,
    required List<Map<String, dynamic>> transaksi,
    required List<Map<String, dynamic>> inventaris,
    required List<Map<String, dynamic>> pergerakan,
  }) async {
    try {
      final excel = ex.Excel.createExcel();

      // Header CellStyle (coklat abon)
      final cellStyle = ex.CellStyle(
        backgroundColorHex: ex.ExcelColor.fromHexString('#8B5E3C'),
        fontColorHex: ex.ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: ex.HorizontalAlign.Center,
        bold: true,
      );

      // 1. Sheet Ringkasan
      final ex.Sheet sheetRingkasan = excel['Ringkasan'];
      excel.delete('Sheet1');

      double totalPenjualan = 0;
      for (var t in transaksi) {
        totalPenjualan += (t['total'] ?? t['grand_total'] ?? 0).toDouble();
      }

      sheetRingkasan.appendRow([ex.TextCellValue('Laporan Ringkasan Bisnis - $namaToko')]);
      sheetRingkasan.appendRow([ex.TextCellValue('Periode: $periode')]);
      sheetRingkasan.appendRow([ex.TextCellValue('')]);
      sheetRingkasan.appendRow([ex.TextCellValue('Indikator'), ex.TextCellValue('Nilai')]);
      sheetRingkasan.appendRow([ex.TextCellValue('Total Penjualan'), ex.TextCellValue('Rp ${NumberFormat('#,###', 'id_ID').format(totalPenjualan)}')]);
      sheetRingkasan.appendRow([ex.TextCellValue('Jumlah Transaksi'), ex.TextCellValue(transaksi.length.toString())]);
      sheetRingkasan.appendRow([ex.TextCellValue('Jumlah Produk di Gudang'), ex.TextCellValue(inventaris.length.toString())]);

      // Style header rows
      for (int i = 0; i < 7; i++) {
        sheetRingkasan.cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i)).cellStyle =
            ex.CellStyle(bold: true);
      }

      // 2. Sheet Detail Transaksi
      final ex.Sheet sheetTransaksi = excel['Detail Transaksi'];
      sheetTransaksi.appendRow([
        ex.TextCellValue('No'),
        ex.TextCellValue('ID Transaksi'),
        ex.TextCellValue('Tanggal/Waktu'),
        ex.TextCellValue('Metode Pembayaran'),
        ex.TextCellValue('Subtotal'),
        ex.TextCellValue('Diskon'),
        ex.TextCellValue('Total'),
      ]);

      // Style header row
      for (int i = 0; i < 7; i++) {
        sheetTransaksi.cell(ex.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = cellStyle;
      }

      for (int idx = 0; idx < transaksi.length; idx++) {
        final t = transaksi[idx];
        sheetTransaksi.appendRow([
          ex.TextCellValue((idx + 1).toString()),
          ex.TextCellValue(t['invoice_number']?.toString() ?? t['id']?.toString() ?? '-'),
          ex.TextCellValue(t['created_at']?.toString() ?? t['tanggal']?.toString() ?? '-'),
          ex.TextCellValue(t['payment_method']?.toString() ?? 'Tunai'),
          ex.TextCellValue('Rp ${NumberFormat('#,###', 'id_ID').format(t['subtotal'] ?? 0)}'),
          ex.TextCellValue('Rp ${NumberFormat('#,###', 'id_ID').format(t['discount'] ?? 0)}'),
          ex.TextCellValue('Rp ${NumberFormat('#,###', 'id_ID').format(t['grand_total'] ?? t['total'] ?? 0)}'),
        ]);
      }

      // 3. Sheet Inventaris
      final ex.Sheet sheetInventaris = excel['Inventaris'];
      sheetInventaris.appendRow([
        ex.TextCellValue('No'),
        ex.TextCellValue('Nama Produk'),
        ex.TextCellValue('Kategori'),
        ex.TextCellValue('Stok'),
        ex.TextCellValue('Harga Jual'),
        ex.TextCellValue('Nilai Stok'),
      ]);

      for (int i = 0; i < 6; i++) {
        sheetInventaris.cell(ex.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = cellStyle;
      }

      for (int idx = 0; idx < inventaris.length; idx++) {
        final p = inventaris[idx];
        final double harga = (p['harga'] ?? p['price'] ?? 0).toDouble();
        final int stok = (p['stok'] ?? p['stock'] ?? 0).toInt();
        final double nilai = harga * stok;

        sheetInventaris.appendRow([
          ex.TextCellValue((idx + 1).toString()),
          ex.TextCellValue(p['name']?.toString() ?? p['nama']?.toString() ?? '-'),
          ex.TextCellValue(p['category']?.toString() ?? p['kategori']?.toString() ?? '-'),
          ex.TextCellValue(stok.toString()),
          ex.TextCellValue('Rp ${NumberFormat('#,###', 'id_ID').format(harga)}'),
          ex.TextCellValue('Rp ${NumberFormat('#,###', 'id_ID').format(nilai)}'),
        ]);
      }

      // 4. Sheet Pergerakan Stok
      final ex.Sheet sheetPergerakan = excel['Pergerakan Stok'];
      sheetPergerakan.appendRow([
        ex.TextCellValue('No'),
        ex.TextCellValue('Tanggal'),
        ex.TextCellValue('Nama Produk'),
        ex.TextCellValue('Tipe Pergerakan'),
        ex.TextCellValue('Jumlah'),
        ex.TextCellValue('Keterangan'),
      ]);

      for (int i = 0; i < 6; i++) {
        sheetPergerakan.cell(ex.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).cellStyle = cellStyle;
      }

      for (int idx = 0; idx < pergerakan.length; idx++) {
        final m = pergerakan[idx];
        sheetPergerakan.appendRow([
          ex.TextCellValue((idx + 1).toString()),
          ex.TextCellValue(m['created_at']?.toString() ?? m['tanggal']?.toString() ?? '-'),
          ex.TextCellValue(m['product_name']?.toString() ?? m['nama_produk']?.toString() ?? '-'),
          ex.TextCellValue(m['type']?.toString() ?? m['tipe']?.toString() ?? '-'),
          ex.TextCellValue((m['quantity'] ?? m['jumlah'] ?? 0).toString()),
          ex.TextCellValue(m['description']?.toString() ?? m['keterangan']?.toString() ?? '-'),
        ]);
      }

      // Save file
      final directory = await getTemporaryDirectory();
      final String filePath =
          '${directory.path}/Laporan_AbonSalakopi_${periode.replaceAll(' ', '_')}.xlsx';
      final file = File(filePath);

      final List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('Error exporting Excel: $e');
      return null;
    }
  }

  /// Export summary report to PDF
  static Future<File?> eksporKePdf({
    required String namaToko,
    required String periode,
    required List<Map<String, dynamic>> transaksi,
    required List<Map<String, dynamic>> inventaris,
  }) async {
    try {
      final pdf = pw.Document();

      double totalPenjualan = 0;
      for (var t in transaksi) {
        totalPenjualan += (t['total'] ?? t['grand_total'] ?? 0).toDouble();
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'LAPORAN BISNIS - $namaToko',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#8B5E3C'),
                    ),
                  ),
                  pw.Text(
                    DateFormat('dd/MM/yyyy').format(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Periode: $periode',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),

            // Summary Info Row
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total Penjualan:', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text(
                      'Rp ${NumberFormat('#,###', 'id_ID').format(totalPenjualan)}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#8B5E3C'),
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Total Transaksi:', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text(
                      '${transaksi.length} Transaksi',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Katalog Produk:', style: const pw.TextStyle(fontSize: 12)),
                    pw.Text(
                      '${inventaris.length} Item',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),

            // Transaksi Table
            pw.Text(
              'Ringkasan Riwayat Transaksi',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#8B5E3C'),
              ),
            ),
            pw.Divider(),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['No', 'Invoice', 'Tanggal', 'Metode', 'Total'],
              data: List<List<dynamic>>.generate(
                transaksi.length > 15 ? 15 : transaksi.length,
                (index) {
                  final t = transaksi[index];
                  return [
                    (index + 1).toString(),
                    t['invoice_number']?.toString() ?? t['id']?.toString() ?? '-',
                    t['created_at']?.toString() ?? t['tanggal']?.toString() ?? '-',
                    t['payment_method']?.toString() ?? 'Tunai',
                    'Rp ${NumberFormat('#,###', 'id_ID').format(t['grand_total'] ?? t['total'] ?? 0)}',
                  ];
                },
              ),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#8B5E3C')),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
              ),
            ),
            if (transaksi.length > 15) ...[
              pw.SizedBox(height: 5),
              pw.Text(
                '*Menampilkan 15 transaksi pertama dari ${transaksi.length} total.',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
            pw.SizedBox(height: 30),

            // Inventaris Table
            pw.Text(
              'Kondisi Inventaris Saat Ini',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#8B5E3C'),
              ),
            ),
            pw.Divider(),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['No', 'Produk', 'Kategori', 'Stok', 'Harga Jual'],
              data: List<List<dynamic>>.generate(
                inventaris.length > 15 ? 15 : inventaris.length,
                (index) {
                  final p = inventaris[index];
                  return [
                    (index + 1).toString(),
                    p['name']?.toString() ?? p['nama']?.toString() ?? '-',
                    p['category']?.toString() ?? p['kategori']?.toString() ?? '-',
                    (p['stok'] ?? p['stock'] ?? 0).toString(),
                    'Rp ${NumberFormat('#,###', 'id_ID').format(p['harga'] ?? p['price'] ?? 0)}',
                  ];
                },
              ),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#8B5E3C')),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
              ),
            ),
            if (inventaris.length > 15) ...[
              pw.SizedBox(height: 5),
              pw.Text(
                '*Menampilkan 15 produk pertama dari ${inventaris.length} total.',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ],
        ),
      );

      final directory = await getTemporaryDirectory();
      final String filePath =
          '${directory.path}/Laporan_AbonSalakopi_${periode.replaceAll(' ', '_')}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      return null;
    }
  }

  /// Export transactions to CSV format
  static Future<File?> eksporKeCsv({
    required String periode,
    required List<Map<String, dynamic>> transaksi,
  }) async {
    try {
      final List<List<dynamic>> csvRows = [];

      // Header
      csvRows.add(['No', 'Invoice', 'Tanggal/Waktu', 'Metode Pembayaran', 'Subtotal', 'Diskon', 'Total']);

      for (int i = 0; i < transaksi.length; i++) {
        final t = transaksi[i];
        csvRows.add([
          (i + 1).toString(),
          t['invoice_number']?.toString() ?? t['id']?.toString() ?? '-',
          t['created_at']?.toString() ?? t['tanggal']?.toString() ?? '-',
          t['payment_method']?.toString() ?? 'Tunai',
          (t['subtotal'] ?? 0).toString(),
          (t['discount'] ?? 0).toString(),
          (t['grand_total'] ?? t['total'] ?? 0).toString(),
        ]);
      }

      // Convert to CSV string with BOM for UTF-8 Excel compatibility
      final csvString = const ListToCsvConverter().convert(csvRows);
      final List<int> csvBytes = [0xEF, 0xBB, 0xBF] + utf8.encode(csvString);

      final directory = await getTemporaryDirectory();
      final String filePath =
          '${directory.path}/Laporan_AbonSalakopi_${periode.replaceAll(' ', '_')}.csv';
      final file = File(filePath);
      await file.writeAsBytes(csvBytes);
      return file;
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
      return null;
    }
  }

  /// Share a file to other apps (WhatsApp, email, drive)
  static Future<void> bagikanFile(File file, {required String subject}) async {
    try {
      final XFile xFile = XFile(file.path);
      await Share.shareXFiles([xFile], subject: subject);
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }
}
