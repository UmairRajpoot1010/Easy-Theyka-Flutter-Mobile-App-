import 'package:flutter/material.dart';

void main() => runApp(MaterialApp(
  home: GrayStructureCostCalculator(),
));

class GrayStructureCostCalculator extends StatefulWidget {
  @override
  _GrayStructureCostCalculatorState createState() => _GrayStructureCostCalculatorState();
}

class _GrayStructureCostCalculatorState extends State<GrayStructureCostCalculator> {
  final _formKey = GlobalKey<FormState>();

  // Inputs
  String selectedCity = "Lahore";
  String areaUnit = "Marla";
  double coveredArea = 0.0;
  String constructionType = "Complete";
  String constructionMode = "With Material";
  String materialQuality = "Standard";
  bool includeLabor = true;
  double contingencyPercent = 5.0;
  int numberOfStories = 1;

  // Custom material prices (user can override)
  double cementPrice = 1100; // per bag
  double steelPrice = 250; // per kg
  double brickPrice = 15; // per brick
  double sandPrice = 80; // per cft
  double crushPrice = 120; // per cft

  // Calculation result
  double totalCost = 0.0;
  double materialCost = 0.0;
  double laborCost = 0.0;
  double contingencyCost = 0.0;

  // Material price multipliers by quality
  final materialQualityMultipliers = {
    "Standard": 1.0,
    "Premium": 1.15,
    "Luxury": 1.3,
  };

  // Area conversion
  final areaConversionFactors = {
    "Marla": 272.25,
    "Kanal": 5450.0,
    "Sq. Ft.": 1.0,
    "Sq. Yard": 9.0,
    "Sq. Meter": 10.764,
    "Acre": 43560.0,
  };

  void calculateCost() {
    double areaInSqFt = coveredArea * (areaConversionFactors[areaUnit] ?? 1.0) * numberOfStories;
    double qualityMultiplier = materialQualityMultipliers[materialQuality] ?? 1.0;

    // Updated material cost calculations with more realistic values
    double cementCost = (areaInSqFt * 0.4) * cementPrice; // 0.4 bags per sq ft
    double steelCost = (areaInSqFt * 3.5) * steelPrice; // 3.5 kg per sq ft
    double brickCost = (areaInSqFt * 60) * brickPrice; // 60 bricks per sq ft
    double sandCost = (areaInSqFt * 2.5) * sandPrice; // 2.5 cft per sq ft
    double crushCost = (areaInSqFt * 2.0) * crushPrice; // 2.0 cft per sq ft

    // Base material cost
    materialCost = (cementCost + steelCost + brickCost + sandCost + crushCost) * qualityMultiplier;

    // Labor cost calculation (updated to more realistic rates)
    double baseLaborRate = 450.0; // Base labor rate per sq ft
    if (constructionType == "Complete") {
      baseLaborRate *= 1.5; // Complete construction requires more labor
    }
    laborCost = includeLabor ? areaInSqFt * baseLaborRate : 0;

    // Additional costs for complete construction
    if (constructionType == "Complete") {
      // Add finishing costs (plaster, paint, tiles, etc.)
      double finishingCost = areaInSqFt * 800 * qualityMultiplier; // 800 PKR per sq ft for basic finishing
      materialCost += finishingCost;
    }

    // Calculate contingency
    contingencyCost = ((materialCost + laborCost) * contingencyPercent) / 100;

    // Total cost
    totalCost = materialCost + laborCost + contingencyCost;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text('Construction Cost Calculator', style: TextStyle(color: Colors.black))),
        // backgroundColor: const Color(0xffF39F1B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCity,
                        decoration: const InputDecoration(
                          labelText: "City",
                          prefixIcon: Icon(Icons.location_city),
                          border: OutlineInputBorder(),
                        ),
                        items: ["Lahore", "Karachi", "Islamabad", "Peshawar", "Quetta", "Multan", "Faisalabad", "Rawalpindi"].map((city) {
                          return DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCity = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 400) {
                            return Column(
                              children: [
                                TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Covered Area',
                                    prefixIcon: Icon(Icons.square_foot),
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter the covered area';
                                    }
                                    if (double.tryParse(value) == null) {
                                      return 'Please enter a valid number';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    coveredArea = double.parse(value!);
                                  },
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: areaUnit,
                                  decoration: const InputDecoration(
                                    labelText: "Area Unit",
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: areaConversionFactors.keys.map((unit) {
                                    return DropdownMenuItem(
                                      value: unit,
                                      child: Text(unit),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      areaUnit = value!;
                                    });
                                  },
                                ),
                              ],
                            );
                          } else {
                            return Row(
                              children: [
                                Flexible(
                                  child: TextFormField(
                                    decoration: const InputDecoration(
                                      labelText: 'Covered Area',
                                      prefixIcon: Icon(Icons.square_foot),
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter the covered area';
                                      }
                                      if (double.tryParse(value) == null) {
                                        return 'Please enter a valid number';
                                      }
                                      return null;
                                    },
                                    onSaved: (value) {
                                      coveredArea = double.parse(value!);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: DropdownButtonFormField<String>(
                                    value: areaUnit,
                                    decoration: const InputDecoration(
                                      labelText: "Area Unit",
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: areaConversionFactors.keys.map((unit) {
                                      return DropdownMenuItem(
                                        value: unit,
                                        child: Text(unit),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        areaUnit = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 400) {
                            return Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: constructionType,
                                  decoration: const InputDecoration(
                                    labelText: "Construction Type",
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: ["GrayStructure", "Complete"].map((type) {
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(type == "GrayStructure" ? "Gray Structure" : "Complete"),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      constructionType = value!;
                                    });
                                  },
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: constructionMode,
                                  decoration: const InputDecoration(
                                    labelText: "Mode",
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  items: ["With Material", "Without Material"].map((mode) {
                                    return DropdownMenuItem(
                                      value: mode,
                                      child: Text(mode),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      constructionMode = value!;
                                    });
                                  },
                                ),
                              ],
                            );
                          } else {
                            return Row(
                              children: [
                                Flexible(
                                  child: DropdownButtonFormField<String>(
                                    value: constructionType,
                                    decoration: const InputDecoration(
                                      labelText: "Construction Type",
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: ["GrayStructure", "Complete"].map((type) {
                                      return DropdownMenuItem(
                                        value: type,
                                        child: Text(type == "GrayStructure" ? "Gray Structure" : "Complete"),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        constructionType = value!;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: DropdownButtonFormField<String>(
                                    value: constructionMode,
                                    decoration: const InputDecoration(
                                      labelText: "Mode",
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: ["With Material", "Without Material"].map((mode) {
                                      return DropdownMenuItem(
                                        value: mode,
                                        child: Text(mode),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        constructionMode = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: materialQuality,
                        decoration: const InputDecoration(
                          labelText: "Material Quality",
                          border: OutlineInputBorder(),
                        ),
                        items: ["Standard", "Premium", "Luxury"].map((q) {
                          return DropdownMenuItem(
                            value: q,
                            child: Text(q),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            materialQuality = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: includeLabor,
                        onChanged: (val) => setState(() => includeLabor = val),
                        title: const Text("Include Labor Cost"),
                        activeColor: Color(0xffF39F1B),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: cementPrice.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Cement Price (per bag)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => cementPrice = double.tryParse(v) ?? cementPrice,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              initialValue: steelPrice.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Steel Price (per kg)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => steelPrice = double.tryParse(v) ?? steelPrice,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: brickPrice.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Brick Price (per brick)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => brickPrice = double.tryParse(v) ?? brickPrice,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              initialValue: sandPrice.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Sand Price (per cft)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => sandPrice = double.tryParse(v) ?? sandPrice,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: crushPrice.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Crush Price (per cft)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => crushPrice = double.tryParse(v) ?? crushPrice,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: contingencyPercent.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Contingency (%)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => contingencyPercent = double.tryParse(v) ?? contingencyPercent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Number of Stories:', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 12),
                          DropdownButton<int>(
                            value: numberOfStories,
                            items: List.generate(5, (i) => i + 1).map((n) => DropdownMenuItem(
                              value: n,
                              child: Text(n.toString()),
                            )).toList(),
                            onChanged: (val) {
                              setState(() {
                                numberOfStories = val!;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.calculate),
                          label: const Text('Calculate Cost'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xffF39F1B),
                            foregroundColor: Colors.white,
                            textStyle: TextStyle(fontSize: 16),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              setState(() {
                                calculateCost();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (totalCost > 0)
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detailed Cost Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Text('Stories: $numberOfStories', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                        _costRow('Material Cost', materialCost),
                        _costRow('Labor Cost', laborCost),
                        _costRow('Contingency', contingencyCost),
                        const Divider(),
                        _costRow('Total Estimated Cost', totalCost, isTotal: true),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _costRow(String label, double value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 18 : 15)),
          Text('PKR ${value.toStringAsFixed(0)}', style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, fontSize: isTotal ? 18 : 15, color: isTotal ? Color(0xffF39F1B) : Colors.black)),
        ],
      ),
    );
  }
}
