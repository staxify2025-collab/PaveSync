import 'package:google_generative_ai/google_generative_ai.dart';

class ChatbotService {
  // PaveQuery specialized knowledge system prompt
  static const String _systemPrompt = '''
You are "PaveQuery", the ultimate GovTech/ConTech compliance assistant for Staxify LLC's PaveSync AI app.
You possess complete and absolute expertise in:
1. FHWA (Federal Highway Administration) HPMS reporting.
2. AASHTO (American Association of State Highway and Transportation Officials) guidelines.
3. ASTM D6433 Pavement Condition Index (PCI) standard (0-100 rating method).
4. PASER (Pavement Surface Evaluation and Rating) visual 1-10 scale.
5. ALDOT (Alabama Department of Transportation) standard specifications.
6. FDOT (Florida Department of Transportation) Pavement Condition Survey (PCS) metrics (Crack, Ride, and Rut ratings on 0-10 scale).

Your tone is professional, technical, authoritative, yet helpful to field highway engineers and inspectors.
When answering, give precise rules, severity level definitions, and standard mathematical or engineering guidance where applicable. Keep responses concise and focused on highway/road standards.
''';

  static GenerativeModel? _model;
  static ChatSession? _chatSession;

  /// Initializes the Gemini model if an API key is available
  static void init(String? apiKey) {
    if (apiKey != null && apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(_systemPrompt),
      );
      _chatSession = _model!.startChat();
    }
  }

  /// Sends a message to Gemini or uses a local knowledge base fallback if offline/no key
  static Future<String> sendMessage(String message) async {
    if (_model != null && _chatSession != null) {
      try {
        final response = await _chatSession!.sendMessage(Content.text(message));
        return response.text ?? 'No response received from PaveQuery.';
      } catch (e) {
        return 'PaveQuery Cloud Connection Error: $e\n\nFalling back to Local Knowledge Base:\n${_getLocalResponse(message)}';
      }
    } else {
      // Local fallback for offline/demo use
      await Future.delayed(const Duration(milliseconds: 800));
      return _getLocalResponse(message);
    }
  }

  /// Reset the current chat session
  static void resetChat() {
    if (_model != null) {
      _chatSession = _model!.startChat();
    }
  }

  /// Local Rule-based compliance chatbot fallback for offline/no-key usage
  static String _getLocalResponse(String message) {
    final query = message.toLowerCase().trim();

    // 1. ALDOT Curbing & Expansion Joints
    if (query.contains('aldot') && (query.contains('curb') || query.contains('joint') || query.contains('expansion'))) {
      return '**ALDOT Section 623 (Concrete Curb, Gutter, and Curbing) Guidelines:**\n'
          '- **Expansion Joints**: Must be placed at maximum intervals of **100 feet**.\n'
          '- **Expansion Joint Material**: 1/2-inch thick preformed joint filler matching the cross-section of the curb.\n'
          '- **Contraction (Control) Joints**: Placed at **10-foot** intervals (dummy joints cut to a depth of at least 1.5 inches).\n'
          '- **Additional Placements**: Expansion joints are also required at all radius points (tangents), inlets, curb returns, and where curbing meets rigid structures (bridges or sidewalks).';
    }

    // 2. ALDOT Asphalt Compaction & Specs
    if (query.contains('aldot') && (query.contains('asphalt') || query.contains('compaction') || query.contains('density') || query.contains('section 410'))) {
      return '**ALDOT Section 410 (Hot Mix Asphalt Pavement) Guidelines:**\n'
          '- **Compaction Density**: Must achieve between **92.0% and 96.0%** of the Maximum Theoretical Specific Gravity (Rice Density).\n'
          '- **Temperature Limits**: The mix must be placed at temperatures between **250°F and 350°F**. Laydown is prohibited if road surface temperature is below **40°F (5°C)**.\n'
          '- **Lift Thickness**: Standard nominal thickness ranges from 1.0 inch (for 9.5mm mix) up to 3.0 inches (for 25.0mm binder mix).';
    }

    // 3. FDOT Expansion Joints / Slab Spacing
    if (query.contains('fdot') && (query.contains('joint') || query.contains('slab') || query.contains('concrete pavement'))) {
      return '**FDOT Section 350 (Concrete Pavement) Guidelines:**\n'
          '- **Contraction Joints**: Transverse joints must be spaced at a maximum of **15 feet** (or 24 times the slab thickness).\n'
          '- **Dowel Bars**: Require corrosion-resistant dowel bars (typically 1.25" to 1.5" diameter) spaced at **12-inch** centers across joints for load transfer.\n'
          '- **Joint Sealant**: Silicone sealant (low modulus) or preformed elastomeric compression seals must be used to prevent water infiltration.';
    }

    // 4. FDOT Cracking Rating
    if (query.contains('fdot') && query.contains('crack')) {
      return '**FDOT Crack Rating (0-10) Guidelines:**\n'
          '- Crack rating is calculated as: Score = 10.0 - Deducts\n'
          '- Deducts are based on Cracking Classes:\n'
          '  * **Class I / 1B**: Hairline cracks, minor load distress. Deduct factor = 0.05 * % area.\n'
          '  * **Class II**: Cracks up to 1/4 inch wide. Deduct factor = 0.15 * % area.\n'
          '  * **Class III**: Cracks > 1/4 inch wide or spalled. Deduct factor = 0.35 * % area.\n'
          '- A rating < 6.0 triggers segment rehabilitation priority in FDOT PMIS.';
    }

    // 5. FDOT Rut Rating
    if (query.contains('fdot') && query.contains('rut')) {
      return '**FDOT Rut Rating (0-10) Guidelines:**\n'
          '- Rut rating is measured based on average rut depth in the wheelpath:\n'
          '  * **<= 1/4 inch (0.25")**: Score = 10\n'
          '  * **3/8 inch (0.375")**: Score = 9\n'
          '  * **1/2 inch (0.50")**: Score = 8\n'
          '  * **5/8 inch (0.625")**: Score = 6\n'
          '  * **3/4 inch (0.75")**: Score = 4\n'
          '  * **> 3/4 inch**: Score = 2\n'
          '- Any rutting > 1/2 inch is considered a high safety hazard for hydroplaning.';
    }

    // 6. PASER Rating
    if (query.contains('paser') || query.contains('driving') || query.contains('scale')) {
      return '**PASER Pavement Surface Rating (1-10 Scale):**\n'
          '- **10-9 (Excellent)**: New construction or overlay. No maintenance.\n'
          '- **8-7 (Good)**: Minor cracking. Routine maintenance (sealcoat/crack seal).\n'
          '- **6-5 (Fair)**: Structural stability good but surface aging. Needs milling/overlay.\n'
          '- **4-3 (Poor)**: Severe cracking, minor rutting/alligatoring. Needs structural overlay.\n'
          '- **2-1 (Failed)**: Complete structural failure. Needs full reconstruction with base repair.';
    }

    // 7. PCI / ASTM D6433
    if (query.contains('pci') || query.contains('astm') || query.contains('d6433') || query.contains('distress')) {
      return '**ASTM D6433 / AASHTO Pavement Condition Index (PCI) Summary:**\n'
          '- PCI is a numerical rating from **0 (Failed)** to **100 (Good)**.\n'
          '- Based on inspecting representative sample units (typically 2,500 sqft +/- 1,000 sqft).\n'
          '- Identifies 19 distress types for asphalt (including Alligator Cracking, Block Cracking, Longitudinal Cracking, Depressions, Potholes, Rutting, Shoving, Weathering, Bleeding).\n'
          '- Uses Deduct Value (DV) curves for each distress type based on density and severity.\n'
          '- Applies a Corrected Deduct Value (CDV) curve to adjust for multiple distresses.';
    }

    // 8. FHWA Dropoff
    if (query.contains('shoulder') || query.contains('dropoff') || query.contains('drop-off')) {
      return '**FHWA Shoulder Drop-off Safety Standards:**\n'
          '- A shoulder drop-off is a vertical elevation difference between the travel lane and the shoulder.\n'
          '- **Low Risk**: < 2 inches. No immediate action required.\n'
          '- **Medium Risk**: 2 to 4 inches. Triggers maintenance grading.\n'
          '- **High Risk**: > 4 inches. Triggers emergency repair. High vehicle rollover hazard.\n'
          '- *ALDOT Section 301* requires aggregate base backfilling to match pavement edge within 72 hours of resurfacing.';
    }

    // 9. Retroreflectivity / Striping
    if (query.contains('striping') || query.contains('retroreflectivity') || query.contains('marking') || query.contains('mutcd')) {
      return '**FHWA Minimum Retroreflectivity Standards (MUTCD Section 3B.01):**\n'
          '- White/Yellow longitudinal lines must maintain:\n'
          '  * **>= 150 mcd/m²/lx** on roads with speed limits >= 70 mph.\n'
          '  * **>= 50 mcd/m²/lx** on roads with speed limits <= 35 mph.\n'
          '- Thermoplastic markings are inspected for percentage wear. If more than 30% of a symbol/legend is degraded, FDOT standard requires replacement.';
    }

    // 10. General curbing expansion joints
    if (query.contains('curb') || query.contains('joint') || query.contains('expansion')) {
      return '**General Curbing Expansion Joint Standards:**\n'
          '- **Expansion Joints**: Spaced every **60 to 100 feet**.\n'
          '- **Contraction Joints**: Spaced every **10 feet**.\n'
          '- Expansion joints are required at all curb returns, structures, and inlets to prevent stress cracking.';
    }

    return 'PaveQuery is online. I can help with AASHTO, FHWA, ASTM D6433, PASER, ALDOT, and FDOT compliance. What road inspection regulation or rating formula would you like to review?';
  }
}
