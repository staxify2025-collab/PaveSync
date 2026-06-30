import 'package:flutter_test/flutter_test.dart';
import 'package:pavesync_ai/models/distress.dart';
import 'package:pavesync_ai/services/voice_assistant_stub.dart'
    if (dart.library.js) 'package:pavesync_ai/services/voice_assistant_web.dart';
import 'package:pavesync_ai/services/formulas/degradation_model.dart';
import 'package:pavesync_ai/services/dispatch_service.dart';

void main() {
  group('PaveSync AI Agentic & Forecasting Calculations', () {
    
    test('Voice assistant parses pothole and severity correctly', () {
      final record = VoiceAssistantService.parseSpeech("severe pothole", "FL");
      expect(record, isNotNull);
      expect(record!.category, DistressCategory.pavement);
      expect(record.specificType, PavementDistressType.pothole.name);
      expect(record.severity, SeverityLevel.high);
    });

    test('Voice assistant parses shoulder drop-off and numerical quantity', () {
      final record = VoiceAssistantService.parseSpeech("shoulder drop-off of 4.5 inches", "AL");
      expect(record, isNotNull);
      expect(record!.category, DistressCategory.shoulder);
      expect(record.specificType, ShoulderDistressType.shoulderDropoff.name);
      expect(record.quantity, 4.5);
    });

    test('Pavement degradation model simulates 10-year curve and correct decay', () {
      final currentPci = 85.0;
      final forecast = PavementDegradationModel.simulate(currentPci, "AL");
      
      expect(forecast.length, 11); // Year 0 to 10
      expect(forecast[0].year, 0);
      expect(forecast[0].pci, currentPci);
      
      // Verify PCI strictly decreases over time
      for (int i = 0; i < forecast.length - 1; i++) {
        expect(forecast[i].pci >= forecast[i + 1].pci, true);
      }
    });

    test('Dispatch service drafts routine work order for empty list', () {
      final wo = DispatchService.draftWorkOrder([]);
      expect(wo.priority, 'None');
      expect(wo.recommendedCrewSize, 0);
    });

    test('Dispatch service drafts urgent work order for high-severity pothole', () {
      final record = DistressRecord(
        id: '1',
        category: DistressCategory.pavement,
        specificType: PavementDistressType.pothole.name,
        severity: SeverityLevel.high,
        quantity: 1.0,
        unit: 'count',
        latitude: 32.0,
        longitude: -86.0,
        timestamp: DateTime.now(),
      );

      final wo = DispatchService.draftWorkOrder([record]);
      expect(wo.priority, 'Urgent (24-72 hrs)');
      expect(wo.recommendedCrewSize, 5);
      expect(wo.requiredEquipment.contains('Asphalt hot patcher'), true);
    });
  });
}
