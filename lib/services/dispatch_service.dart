import '../models/distress.dart';

class WorkOrderDraft {
  final String orderId;
  final String priority;
  final int recommendedCrewSize;
  final List<String> requiredEquipment;
  final double estimatedLaborHours;
  final String safetyWarning;

  WorkOrderDraft({
    required this.orderId,
    required this.priority,
    required this.recommendedCrewSize,
    required this.requiredEquipment,
    required this.estimatedLaborHours,
    required this.safetyWarning,
  });
}

class DispatchService {
  /// Automatically generates a maintenance work order draft based on pavement defects
  static WorkOrderDraft draftWorkOrder(List<DistressRecord> distresses) {
    final orderId = 'WO-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    
    // Determine priority
    String priority = 'Routine';
    int crewSize = 3;
    double laborHours = 8.0;
    List<String> equipment = ['Hand tools', 'Safety cones', 'Light utility truck'];
    String safetyWarning = 'Wear Class 3 high-visibility vests. Set up standard MUTCD lane closures.';

    if (distresses.isEmpty) {
      return WorkOrderDraft(
        orderId: orderId,
        priority: 'None',
        recommendedCrewSize: 0,
        requiredEquipment: [],
        estimatedLaborHours: 0.0,
        safetyWarning: 'No action required.',
      );
    }

    bool hasPothole = distresses.any((d) => d.specificType == 'pothole');
    bool hasSevereDropoff = distresses.any((d) => d.specificType == 'shoulderDropoff' && d.quantity > 3.0);
    bool hasHighAlligator = distresses.any((d) => d.specificType == 'alligatorCracking' && d.severity == SeverityLevel.high);

    // Apply rules to estimate work order scope
    if (hasSevereDropoff || (hasPothole && distresses.any((d) => d.severity == SeverityLevel.high))) {
      priority = 'Urgent (24-72 hrs)';
      crewSize = 5;
      laborHours = 12.0;
      equipment.addAll(['Asphalt hot patcher', 'Aggregate base spreader', 'Vibratory plate compactor']);
      safetyWarning = 'CRITICAL: Severe drop-off hazard detected. Set up temporary active warning signs immediately.';
    } else if (hasHighAlligator || hasPothole) {
      priority = 'High';
      crewSize = 4;
      laborHours = 16.0;
      equipment.addAll(['Tack distributor', 'Pavement saw', 'Compact double-drum roller']);
    } else {
      // Minor cracks / striping issues
      priority = 'Routine (Scheduled)';
      crewSize = 3;
      laborHours = 6.0;
      equipment.addAll(['Thermoplastic paint applicator', 'Crack sealing kettle']);
    }

    // De-duplicate equipment list
    equipment = equipment.toSet().toList();

    return WorkOrderDraft(
      orderId: orderId,
      priority: priority,
      recommendedCrewSize: crewSize,
      requiredEquipment: equipment,
      estimatedLaborHours: laborHours,
      safetyWarning: safetyWarning,
    );
  }
}
