import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../utils/vaccination_schedule.dart';

class ParentReportPage extends StatelessWidget {
  final Map<String, dynamic> child;
  final int ageInMonths;
  final List<VaccineScheduleItem> recommended;
  final List<Map<String, dynamic>> completedAppointments;
  final List<Map<String, dynamic>> pendingAppointments;

  const ParentReportPage({
    super.key,
    required this.child,
    required this.ageInMonths,
    required this.recommended,
    required this.completedAppointments,
    required this.pendingAppointments,
  });

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Vaccination Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Header(
              level: 1,
              child: pw.Text(
                'Child Information',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.purple700,
                ),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Name', child['name'] ?? 'N/A'),
                  _buildInfoRow(
                    'Age',
                    '$ageInMonths months '
                    '(${(ageInMonths / 12).toStringAsFixed(1)} years)',
                  ),
                  _buildInfoRow('Gender', child['gender'] ?? 'N/A'),
                  _buildInfoRow(
                    'Allergies',
                    (child['allergies'] as List?)?.join(', ') ?? 'None',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Header(
              level: 1,
              child: pw.Text(
                'Vaccinations Completed (${completedAppointments.length})',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green700,
                ),
              ),
            ),
            if (completedAppointments.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'No vaccinations given yet',
                  style: pw.TextStyle(color: PdfColors.grey700),
                ),
              )
            else
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: completedAppointments.map((appt) {
                  final doctorDetails = appt['doctor_details'];
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      color: PdfColors.grey100,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          appt['vaccination_name'] ?? 'Unknown',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Provided by: Dr. ${doctorDetails?['name'] ?? 'Unknown'}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.Text(
                          'Date: ${appt['service_provided_at']?.toString().split(' ')[0] ?? appt['updated_at']?.toString().split(' ')[0] ?? 'N/A'}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        if (doctorDetails?['specialization'] != null)
                          pw.Text(
                            'Specialization: ${doctorDetails['specialization']}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              color: PdfColors.grey700,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            pw.SizedBox(height: 20),
            pw.Header(
              level: 1,
              child: pw.Text(
                'Upcoming Appointments (${pendingAppointments.length})',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue700,
                ),
              ),
            ),
            if (pendingAppointments.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  'No upcoming appointments',
                  style: pw.TextStyle(color: PdfColors.grey700),
                ),
              )
            else
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: pendingAppointments.map((appt) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      color: PdfColors.blue100,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          appt['vaccination_name'] ?? 'Unknown',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Status: ${appt['status']}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        pw.Text(
                          'Scheduled: ${appt['date']?.toString().split(' ')[0] ?? 'N/A'}',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            pw.SizedBox(height: 20),
            pw.Header(
              level: 1,
              child: pw.Text(
                'Recommended Vaccinations for Age',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange700,
                ),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                color: PdfColors.orange50,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: recommended.take(10).map((vaccine) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      children: [
                        pw.Text('• ', style: pw.TextStyle(fontSize: 16)),
                        pw.Expanded(
                          child: pw.Text(
                            vaccine.vaccine,
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            pw.Spacer(),
            pw.Divider(),
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 20),
              child: pw.Text(
                'Generated on ${DateTime.now().toString().split('.')[0]}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Vaccination Report: ${child['name']}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _generatePDF,
            tooltip: 'Download PDF',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReportSection(
              title: "Child Information",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow("Name", child['name'] ?? 'N/A'),
                  _InfoRow(
                      "Age",
                      '$ageInMonths months '
                      '(${(ageInMonths / 12).toStringAsFixed(1)} years)'),
                  _InfoRow("Gender", child['gender'] ?? 'N/A'),
                  _InfoRow(
                      "Allergies",
                      (child['allergies'] as List?)?.join(', ') ?? 'None'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _ReportSection(
              title: "Vaccinations Completed (${completedAppointments.length})",
              child: completedAppointments.isEmpty
                  ? const Text("No vaccinations given yet",
                      style: TextStyle(color: Colors.grey))
                  : Column(
                      children: completedAppointments.map((appt) {
                        final doctorDetails = appt['doctor_details'];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(appt['vaccination_name'] ?? 'Unknown',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  'Provided by: Dr. ${doctorDetails?['name'] ?? 'Unknown'}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                Text(
                                  'Date: ${appt['service_provided_at']?.toString().split(' ')[0] ?? 'N/A'}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 20),
            _ReportSection(
              title: "Upcoming Appointments (${pendingAppointments.length})",
              child: pendingAppointments.isEmpty
                  ? const Text("No upcoming appointments",
                      style: TextStyle(color: Colors.grey))
                  : Column(
                      children: pendingAppointments.map((appt) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(appt['vaccination_name'] ?? 'Unknown',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('Status: ${appt['status']}'),
                                Text(
                                  'Scheduled: ${appt['date']?.toString().split(' ')[0] ?? 'N/A'}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 20),
            _ReportSection(
              title: "Recommended Vaccinations for Age",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: recommended.take(5).map((vaccine) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.vaccines, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text(vaccine.vaccine)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReportSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label + ':',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
