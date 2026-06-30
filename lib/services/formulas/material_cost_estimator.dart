import '../../models/distress.dart';

class MaterialQuantity {
  final String materialName;
  final double quantity;
  final String unit;
  final double estimatedCost;

  MaterialQuantity({
    required this.materialName,
    required this.quantity,
    required this.unit,
    required this.estimatedCost,
  });
}

class EstimationResult {
  final List<MaterialQuantity> materialList;
  final double totalEstimatedCost;
  final List<String> recommendedActions;

  EstimationResult({
    required this.materialList,
    required this.totalEstimatedCost,
    required this.recommendedActions,
  });
}

class MaterialCostEstimator {
  /// Estimates quantities and costs for repairing all logged distresses in a segment,
  /// adjusting unit prices depending on the target state DOT (ALDOT vs FDOT).
  static EstimationResult estimate(List<DistressRecord> distresses, String state) {
    List<MaterialQuantity> materials = [];
    List<String> actions = [];
    double totalCost = 0.0;

    // Define state-specific unit rates (ALDOT vs FDOT average bid prices)
    final double asphaltPricePerTon = state == 'FL' ? 135.0 : 120.0; // Hot Mix Asphalt
    final double shoulderGravelPerTon = state == 'FL' ? 52.0 : 45.0; // Crushed stone base
    final double thermoplasticPerFoot = state == 'FL' ? 1.45 : 1.25; // Thermoplastic paint
    final double trafficPaintPerFoot = state == 'FL' ? 0.32 : 0.25; // Standard latex paint
    final double rpmCostEach = state == 'FL' ? 5.50 : 4.80; // Raised Pavement Markers

    for (var distress in distresses) {
      if (distress.category == DistressCategory.pavement) {
        if (distress.specificType == PavementDistressType.pothole.name) {
          // Quantity = count of potholes. Estimate 3 sqft area, 4 inches deep per pothole on average.
          // Volume per pothole = 3 * (4/12) = 1 cubic foot.
          // Weight of asphalt = 1 cuft * 145 lbs/cuft = 145 lbs = 0.0725 tons per pothole.
          double count = distress.quantity;
          double tonsNeeded = count * 0.0725;
          double cost = tonsNeeded * asphaltPricePerTon + (count * 150.0); // Add labor flat rate per patch
          
          materials.add(MaterialQuantity(
            materialName: 'Hot Mix Asphalt (Patching)',
            quantity: double.parse(tonsNeeded.toStringAsFixed(3)),
            unit: 'tons',
            estimatedCost: double.parse(cost.toStringAsFixed(2)),
          ));
          actions.add('Execute local deep-patching on $count pothole(s).');
        } 
        
        else if (distress.specificType == PavementDistressType.alligatorCracking.name) {
          // Quantity = percentage area affected of standard 100m segment (approx 2400 sqft lane area).
          // For high severity, recommended action is mill & overlay (2" depth).
          // Volume = area * (2/12). Asphalt weight = Vol * 145 lbs/cuft.
          double pct = distress.quantity;
          double areaSqFt = (pct / 100.0) * 2400.0;
          double tonsNeeded = areaSqFt * (2.0 / 12.0) * 145.0 / 2000.0;
          
          double cost = tonsNeeded * asphaltPricePerTon;
          if (distress.severity == SeverityLevel.high) {
            cost += areaSqFt * 1.50; // Add milling cost per sqft
            actions.add('Mill and Overlay (2" depth) on alligator cracked area (${pct.toStringAsFixed(1)}%).');
          } else {
            actions.add('Apply skin patching or asphalt sealant over alligator cracked area (${pct.toStringAsFixed(1)}%).');
          }

          materials.add(MaterialQuantity(
            materialName: 'Hot Mix Asphalt (Mill & Overlay)',
            quantity: double.parse(tonsNeeded.toStringAsFixed(2)),
            unit: 'tons',
            estimatedCost: double.parse(cost.toStringAsFixed(2)),
          ));
        }

        else if (distress.specificType == PavementDistressType.longitudinalTransverseCracking.name) {
          // Crack sealing. Quantity = linear feet of cracks.
          // Rubberized joint sealant: 0.1 lbs per linear foot. Price = $2.50 per lb ($25 per linear foot installed)
          double linearFeet = distress.quantity;
          double lbsSealant = linearFeet * 0.1;
          double cost = linearFeet * (state == 'FL' ? 2.80 : 2.40);

          materials.add(MaterialQuantity(
            materialName: 'Rubberized Crack Sealant',
            quantity: double.parse(lbsSealant.toStringAsFixed(1)),
            unit: 'lbs',
            estimatedCost: double.parse(cost.toStringAsFixed(2)),
          ));
          actions.add('Clean and seal ${linearFeet.toStringAsFixed(0)} LF of longitudinal/transverse cracks.');
        }
      } 
      
      else if (distress.category == DistressCategory.shoulder) {
        if (distress.specificType == ShoulderDistressType.shoulderDropoff.name) {
          // Quantity = drop-off depth in inches. Let's assume length is 150 ft on average if logged,
          // and shoulder width is 2 ft.
          // Volume = 150 * 2 * (depth / 12) cuft. Crushed stone = Vol * 135 lbs/cuft.
          double depth = distress.quantity;
          double length = 150.0; // standard default length
          double tonsStone = length * 2.0 * (depth / 12.0) * 135.0 / 2000.0;
          double cost = tonsStone * shoulderGravelPerTon + 250.0; // add grader machinery cost

          materials.add(MaterialQuantity(
            materialName: 'Crushed Aggregate Base (Shoulder Backfill)',
            quantity: double.parse(tonsStone.toStringAsFixed(2)),
            unit: 'tons',
            estimatedCost: double.parse(cost.toStringAsFixed(2)),
          ));
          actions.add('Backfill shoulder drop-off (${depth.toStringAsFixed(1)}" depth) with graded aggregate.');
        }
        
        else if (distress.specificType == ShoulderDistressType.shoulderErosion.name) {
          // Quantity = linear feet of erosion. Repair with aggregate backfill.
          double lf = distress.quantity;
          double tonsStone = lf * 2.0 * (4.0 / 12.0) * 135.0 / 2000.0; // assume 4" avg wash depth
          double cost = tonsStone * shoulderGravelPerTon;

          materials.add(MaterialQuantity(
            materialName: 'Crushed Aggregate Base (Erosion Fill)',
            quantity: double.parse(tonsStone.toStringAsFixed(2)),
            unit: 'tons',
            estimatedCost: double.parse(cost.toStringAsFixed(2)),
          ));
          actions.add('Regrade and fill ${lf.toStringAsFixed(0)} LF of shoulder erosion washouts.');
        }
      } 
      
      else if (distress.category == DistressCategory.striping) {
        if (distress.specificType == StripingDistressType.paintWear.name) {
          // Quantity = linear feet of striping to re-apply.
          double lf = distress.quantity;
          double cost = lf * thermoplasticPerFoot; // default to thermoplastic for highways

          materials.add(MaterialQuantity(
            materialName: 'Thermoplastic Traffic Stripe (White/Yellow)',
            quantity: lf,
            unit: 'linear feet',
            estimatedCost: double.parse(cost.toStringAsFixed(2)),
          ));
          actions.add('Re-stripe ${lf.toStringAsFixed(0)} LF of degraded pavement lines.');
        }
        
        else if (distress.specificType == StripingDistressType.missingRPMs.name) {
          // Quantity = count of missing reflectors
          double count = distress.quantity;
          double cost = count * rpmCostEach;

          materials.add(MaterialQuantity(
            materialName: 'Raised Pavement Markers (RPMs)',
            quantity: count,
            unit: 'count',
            estimatedCost: double.parse(cost.toStringAsFixed(2)),
          ));
          actions.add('Install $count new retroreflective pavement markers (RPMs).');
        }
      }
    }

    // Combine identical materials to avoid duplicates
    Map<String, MaterialQuantity> combinedMaterials = {};
    for (var m in materials) {
      if (combinedMaterials.containsKey(m.materialName)) {
        var existing = combinedMaterials[m.materialName]!;
        combinedMaterials[m.materialName] = MaterialQuantity(
          materialName: m.materialName,
          quantity: existing.quantity + m.quantity,
          unit: m.unit,
          estimatedCost: existing.estimatedCost + m.estimatedCost,
        );
      } else {
        combinedMaterials[m.materialName] = m;
      }
    }

    List<MaterialQuantity> finalMaterialsList = combinedMaterials.values.toList();
    totalCost = finalMaterialsList.fold(0.0, (s, m) => s + m.estimatedCost);

    return EstimationResult(
      materialList: finalMaterialsList,
      totalEstimatedCost: double.parse(totalCost.toStringAsFixed(2)),
      recommendedActions: actions,
    );
  }
}
