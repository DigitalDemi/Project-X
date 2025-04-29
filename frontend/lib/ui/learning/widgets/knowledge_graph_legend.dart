// lib/ui/learning/widgets/knowledge_graph_legend.dart

import 'package:flutter/material.dart';

// Helper function to get display color for legend items.
// Can be moved to a shared utility/helper file if used elsewhere.
Color getStageColorForLegend(String stage) {
  // Using slightly less transparent/more distinct colors for the legend swatch
  switch (stage.toLowerCase()) {
    case 'first_time': return Colors.red[400]!;
    case 'early_stage': return Colors.orange[400]!;
    case 'mid_stage': return Colors.yellow[700]!; // Darker yellow for better visibility
    case 'late_stage': return Colors.green[400]!;
    case 'mastered': return Colors.blue[400]!;
    default: return Colors.grey[600]!; // Color for unknown/default stages
  }
}

// Helper function to get readable stage names for the legend.
// Can also be moved to a shared utility/helper file.
String getReadableStageName(String stage) {
   switch (stage.toLowerCase()) {
      case 'first_time': return 'First Time';
      case 'early_stage': return 'Early Stage';
      case 'mid_stage': return 'Mid Stage';
      case 'late_stage': return 'Late Stage';
      case 'mastered': return 'Mastered';
      default: return 'Unknown';
    }
}

// Displays the legend mapping stage colors to names for the Knowledge Graph.
class KnowledgeGraphLegend extends StatelessWidget {
  const KnowledgeGraphLegend({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the stages to include in the legend
    final stages = [
      'first_time',
      'early_stage',
      'mid_stage',
      'late_stage',
      'mastered',
      // Include 'default' if you want to show the color for unknown stages
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, left: 4.0, right: 4.0), // Add some padding
      child: Wrap( // Use Wrap to allow legend items to flow to the next line if needed
        spacing: 16.0, // Horizontal space between legend items
        runSpacing: 8.0, // Vertical space between lines of items
        alignment: WrapAlignment.center, // Center the items horizontally
        children: stages.map((stage) => _buildLegendItem(stage)).toList(),
      ),
    );
  }

  // Builds a single item (color swatch + text) for the legend.
  Widget _buildLegendItem(String stage) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Keep row contents close together
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: getStageColorForLegend(stage),
            shape: BoxShape.circle, // Use circles for color swatches
             border: Border.all(color: Colors.white30, width: 1) // Optional subtle border
          ),
        ),
        const SizedBox(width: 6), // Space between swatch and text
        Text(
          getReadableStageName(stage),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}