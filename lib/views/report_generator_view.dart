import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/segment.dart';
import '../services/formulas/material_cost_estimator.dart';
import '../services/formulas/paser_calc.dart';
import '../services/formulas/degradation_model.dart';
import '../services/dispatch_service.dart';
import '../services/proposal_service.dart';

class ReportGeneratorView extends StatelessWidget {
  final RoadSegment segment;
  final VoidCallback onSyncPressed;

  const ReportGeneratorView({
    super.key,
    required this.segment,
    required this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Perform AI material estimation
    final estimation = MaterialCostEstimator.estimate(segment.distresses, segment.state);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      segment.roadName.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF101828)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Milepost ${segment.startMilepost.toStringAsFixed(2)} to ${segment.endMilepost.toStringAsFixed(2)} (${segment.lengthInMiles.toStringAsFixed(2)} mi) | ${segment.state == "FL" ? "FDOT" : "ALDOT"} ruleset',
                      style: const TextStyle(color: Color(0xFF475467), fontSize: 13),
                    ),
                  ],
                ),
                // Sync status indicator chip
                Chip(
                  avatar: Icon(
                    segment.isSynced ? Icons.cloud_done : Icons.cloud_queue,
                    color: segment.isSynced ? Colors.green[700] : Colors.orange[700],
                    size: 16,
                  ),
                  backgroundColor: segment.isSynced ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  side: BorderSide(color: segment.isSynced ? Colors.green : Colors.orange, width: 0.8),
                  label: Text(
                    segment.isSynced ? 'CLOUD SYNCED' : 'OFFLINE QUEUED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: segment.isSynced ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.black12, height: 32),

            // Compliance Scores grid
            const Text(
              'AASHTO & STATE COMPLIANCE SCORES',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.amber),
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
              children: [
                // PCI Score
                _buildScoreCard(
                  'ASTM D6433 PCI',
                  '${segment.calculatedPci?.toStringAsFixed(1) ?? "N/A"} / 100',
                  _getPciColor(segment.calculatedPci),
                  'Pavement Condition Index',
                ),
                // PASER Score
                _buildScoreCard(
                  'PASER Rating',
                  '${segment.paserScore ?? PaserCalculator.estimatePaserFromPci(segment.calculatedPci ?? 100.0)} / 10',
                  _getPaserColor(segment.paserScore),
                  PaserCalculator.getCondition(
                    segment.paserScore ?? PaserCalculator.estimatePaserFromPci(segment.calculatedPci ?? 100.0)
                  ),
                ),
                if (segment.state == 'FL') ...[
                  // FDOT Crack Score
                  _buildScoreCard(
                    'FDOT Crack Rating',
                    '${segment.fdotCrackRating?.toStringAsFixed(1) ?? "10.0"} / 10',
                    _getFdotColor(segment.fdotCrackRating),
                    'PCS Crack Index',
                  ),
                  // FDOT Rut Score
                  _buildScoreCard(
                    'FDOT Rut Rating',
                    '${segment.fdotRutRating?.toStringAsFixed(1) ?? "10.0"} / 10',
                    _getFdotColor(segment.fdotRutRating),
                    'PCS Rut Index',
                  ),
                ] else ...[
                  _buildScoreCard(
                    'ALDOT Priority Factor',
                    '8.4 / 10',
                    Colors.blue[800]!,
                    'Routine Resurfacing Priority',
                  ),
                  _buildScoreCard(
                    'Shoulder Safety Index',
                    segment.distresses.any((d) => d.specificType == 'shoulderDropoff' && d.quantity > 3.0)
                        ? 'CRITICAL'
                        : 'COMPLIANT',
                    segment.distresses.any((d) => d.specificType == 'shoulderDropoff' && d.quantity > 3.0)
                        ? Colors.red[800]!
                        : Colors.green[700]!,
                    'Shoulder drop-off check',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),

            // Material Quantification table
            const Text(
              'MATERIAL QUANTIFICATION & COST ESTIMATION',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.amber),
            ),
            const SizedBox(height: 16),
            
            if (estimation.materialList.isEmpty)
              const Card(
                color: Color(0xFFF2F4F7),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('No repair materials needed for this segment.', style: TextStyle(color: Color(0xFF475467))),
                  ),
                ),
              )
            else ...[
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(1.5),
                },
                border: TableBorder.all(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFEAECF0)),
                    children: [
                      _buildTableHeader('Material Description'),
                      _buildTableHeader('Quantity Needed'),
                      _buildTableHeader('Est. Cost'),
                    ],
                  ),
                  ...estimation.materialList.map((m) {
                    return TableRow(
                      children: [
                        _buildTableCell(m.materialName),
                        _buildTableCell('${m.quantity.toStringAsFixed(1)} ${m.unit}'),
                        _buildTableCell('\$${m.estimatedCost.toStringAsFixed(2)}', isBold: true, color: Colors.green[800]),
                      ],
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Total Estimated Repair Cost: ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                  Text(
                    '\$${estimation.totalEstimatedCost.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[800]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),

            // FHWA/State Compliance Actions checklist
            const Text(
              'COMPLIANCE RECOMMENDED ACTIONS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.amber),
            ),
            const SizedBox(height: 12),
            if (estimation.recommendedActions.isEmpty)
              const Text('No compliance action items flagged.', style: TextStyle(color: Color(0xFF475467), fontSize: 13))
            else
              ...estimation.recommendedActions.map((action) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green[700], size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          action,
                          style: const TextStyle(color: Color(0xFF1D2939), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 32),

            // AI Predictive Degradation Section
            const Text(
              'AASHTO PREDICTIVE DEGRADATION TIMELINE (10-YEAR)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.amber),
            ),
            const SizedBox(height: 12),
            _buildDegradationTimeline(context),
            const SizedBox(height: 32),

            // AI Maintenance Dispatch Scheduler Section
            const Text(
              'CREW DISPATCH & MAINTENANCE WORK ORDER',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.amber),
            ),
            const SizedBox(height: 12),
            _buildDispatchScheduler(context),
            const SizedBox(height: 32),

            // AI FHWA Grant & Funding Proposal Section
            const Text(
              'AI FHWA GRANT & FUNDING PROPOSAL DRAFTER',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.amber),
            ),
            const SizedBox(height: 12),
            _buildProposalDrafter(context),
            const SizedBox(height: 32),

            // Export Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEAECF0),
                      foregroundColor: const Color(0xFF1D2939),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.black12),
                    ),
                    onPressed: () => _simulatePdfExport(context),
                    icon: Icon(Icons.picture_as_pdf, color: Colors.red[700]),
                    label: const Text('Export PDF Report', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEAECF0),
                      foregroundColor: const Color(0xFF1D2939),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.black12),
                    ),
                    onPressed: () => _simulateGisExport(context),
                    icon: Icon(Icons.map, color: Colors.cyan[700]),
                    label: const Text('Export GeoJSON / GIS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                if (!segment.isSynced)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: onSyncPressed,
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync to Cloud', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(String title, String score, Color color, String subtitle) {
    return Card(
      color: const Color(0xFFF2F4F7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 10, color: Color(0xFF475467))),
            Text(
              score,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color),
            ),
            Text(subtitle, style: const TextStyle(fontSize: 9, color: Color(0xFF475467))),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF475467)),
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? const Color(0xFF101828),
        ),
      ),
    );
  }

  Color _getPciColor(double? pci) {
    if (pci == null) return Colors.grey;
    if (pci >= 85) return Colors.greenAccent;
    if (pci >= 70) return Colors.lightGreen;
    if (pci >= 55) return Colors.yellow;
    if (pci >= 40) return Colors.orange;
    return Colors.redAccent;
  }

  Color _getPaserColor(int? paser) {
    if (paser == null) return Colors.grey;
    if (paser >= 8) return Colors.greenAccent;
    if (paser >= 5) return Colors.yellow;
    if (paser >= 3) return Colors.orange;
    return Colors.redAccent;
  }

  Color _getFdotColor(double? rating) {
    if (rating == null) return Colors.greenAccent;
    if (rating >= 8.0) return Colors.greenAccent;
    if (rating >= 6.5) return Colors.yellow;
    return Colors.redAccent;
  }

  void _simulatePdfExport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('FHWA & ${segment.state == "FL" ? "FDOT" : "ALDOT"} compliant PDF Report exported successfully to Documents/PaveSync/Reports/'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _simulateGisExport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Geotagged Shapefile/GeoJSON generated with ${segment.distresses.length} feature layers.'),
        backgroundColor: Colors.cyan[800],
      ),
    );
  }

  Widget _buildDegradationTimeline(BuildContext context) {
    final forecast = PavementDegradationModel.simulate(segment.calculatedPci ?? 100.0, segment.state);
    
    final milestones = [
      forecast[0],
      forecast.length > 3 ? forecast[3] : forecast.last,
      forecast.length > 6 ? forecast[6] : forecast.last,
      forecast.last,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: milestones.map((pt) {
          final isFirst = milestones.indexOf(pt) == 0;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getPciColor(pt.pci),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (milestones.indexOf(pt) != milestones.length - 1)
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.black12,
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isFirst ? 'Year 0 (Current)' : 'Year ${pt.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF101828)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getPciColor(pt.pci).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'PCI: ${pt.pci.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getPciColor(pt.pci),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Recommended: ${pt.recommendedTreatment}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF475467)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDispatchScheduler(BuildContext context) {
    final wo = DispatchService.draftWorkOrder(segment.distresses);
    
    if (wo.priority == 'None') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50]!,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700]),
            const SizedBox(width: 10),
            const Text(
              'No structural defects logged. Dispatch scheduler idle.',
              style: TextStyle(color: Color(0xFF027A48), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final isUrgent = wo.priority.contains('Urgent');

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  wo.orderId,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF101828)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUrgent ? Colors.red[50] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isUrgent ? Colors.red[200]! : Colors.blue[200]!),
                  ),
                  child: Text(
                    wo.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isUrgent ? Colors.red[800] : Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Colors.black12),
            Row(
              children: [
                Expanded(
                  child: _buildWorkStat(Icons.people, 'Crew Size', '${wo.recommendedCrewSize} workers'),
                ),
                Expanded(
                  child: _buildWorkStat(Icons.timer, 'Labor Hours', '${wo.estimatedLaborHours.toStringAsFixed(1)} hrs'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'REQUIRED VEHICLES & EQUIPMENT',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475467)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: wo.requiredEquipment.map((eq) {
                return Chip(
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  backgroundColor: const Color(0xFFF2F4F7),
                  side: BorderSide.none,
                  label: Text(eq, style: const TextStyle(fontSize: 10, color: Color(0xFF1D2939))),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUrgent ? Colors.red[50] : Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isUrgent ? Colors.red[100]! : Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: isUrgent ? Colors.red[800] : Colors.amber[800], size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      wo.safetyWarning,
                      style: TextStyle(
                        fontSize: 11,
                        color: isUrgent ? Colors.red[900] : Colors.amber[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.amber[800], size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF475467))),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF101828))),
          ],
        ),
      ],
    );
  }

  Widget _buildProposalDrafter(BuildContext context) {
    final proposalText = ProposalService.draftProposal(segment);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFEAECF0),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'FHWA Funding Allocation Proposal Draft',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1D2939)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1D2939),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: const BorderSide(color: Colors.black12),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: proposalText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('AI Grant Proposal copied to clipboard!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('Copy Draft', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
          Container(
            height: 140,
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              child: Text(
                proposalText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Color(0xFF344054),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
