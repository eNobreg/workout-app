import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';

/// Data type for the chart.
enum ChartDataType { weight, reps }

/// A line chart widget for displaying exercise progress over time.
/// Supports weight and reps data with optional overlay.
class ProgressChart extends StatefulWidget {
  /// List of session sets to display.
  final List<SessionSet> sets;

  /// Chart title.
  final String title;

  /// Y-axis label.
  final String yAxisLabel;

  /// Type of data to display.
  final ChartDataType dataType;

  /// Whether to show both weight and reps overlaid.
  final bool showOverlay;

  /// Callback when a data point is tapped.
  final void Function(SessionSet set)? onPointTap;

  const ProgressChart({
    super.key,
    required this.sets,
    required this.title,
    required this.yAxisLabel,
    required this.dataType,
    this.showOverlay = false,
    this.onPointTap,
  });

  @override
  State<ProgressChart> createState() => _ProgressChartState();
}

class _ProgressChartState extends State<ProgressChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.sets.isEmpty) {
      return _buildEmptyState(theme);
    }

    final weightSpots = _buildWeightSpots();
    final repsSpots = _buildRepsSpots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 250,
          child: Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateInterval(),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: _calculateDateInterval(),
                      getTitlesWidget: _buildBottomTitle,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        widget.yAxisLabel,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: _buildLeftTitle,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.colorScheme.outline,
                      width: 1,
                    ),
                    left: BorderSide(
                      color: theme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                ),
                minX: _getMinX(),
                maxX: _getMaxX(),
                minY: 0,
                maxY: _getMaxY(),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (spot) =>
                        theme.colorScheme.surfaceContainerHighest,
                    tooltipRoundedRadius: 8,
                    getTooltipItems: _buildTooltipItems,
                  ),
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent && response?.lineBarSpots != null) {
                      final spot = response!.lineBarSpots!.first;
                      final index = spot.spotIndex;
                      if (index < widget.sets.length) {
                        widget.onPointTap?.call(widget.sets[index]);
                      }
                    }
                    setState(() {
                      if (response?.lineBarSpots != null &&
                          response!.lineBarSpots!.isNotEmpty) {
                        _touchedIndex = response.lineBarSpots!.first.spotIndex;
                      } else {
                        _touchedIndex = null;
                      }
                    });
                  },
                ),
                lineBarsData: _buildLineBarsData(
                  theme,
                  weightSpots,
                  repsSpots,
                ),
              ),
            ),
          ),
        ),
        if (widget.showOverlay) _buildLegend(theme),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SizedBox(
      height: 250,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'No data yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            Text(
              'Complete some sets to see your progress',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _buildWeightSpots() {
    return widget.sets
        .asMap()
        .entries
        .where((e) => e.value.weight != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value.weight!))
        .toList();
  }

  List<FlSpot> _buildRepsSpots() {
    return widget.sets
        .asMap()
        .entries
        .where((e) => e.value.reps != null)
        .map((e) => FlSpot(e.key.toDouble(), e.value.reps!.toDouble()))
        .toList();
  }

  List<LineChartBarData> _buildLineBarsData(
    ThemeData theme,
    List<FlSpot> weightSpots,
    List<FlSpot> repsSpots,
  ) {
    final bars = <LineChartBarData>[];

    if (widget.showOverlay) {
      // Show both weight and reps
      if (weightSpots.isNotEmpty) {
        bars.add(_buildLineBarData(
          spots: weightSpots,
          color: Colors.blue,
          theme: theme,
        ));
      }
      if (repsSpots.isNotEmpty) {
        bars.add(_buildLineBarData(
          spots: repsSpots,
          color: Colors.green,
          theme: theme,
        ));
      }
    } else {
      // Show only selected type
      final spots = widget.dataType == ChartDataType.weight
          ? weightSpots
          : repsSpots;
      final color = widget.dataType == ChartDataType.weight
          ? Colors.blue
          : Colors.green;

      if (spots.isNotEmpty) {
        bars.add(_buildLineBarData(
          spots: spots,
          color: color,
          theme: theme,
        ));
      }
    }

    return bars;
  }

  LineChartBarData _buildLineBarData({
    required List<FlSpot> spots,
    required Color color,
    required ThemeData theme,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          final isTouched = _touchedIndex == index;
          return FlDotCirclePainter(
            radius: isTouched ? 6 : 4,
            color: color,
            strokeWidth: 2,
            strokeColor: theme.colorScheme.surface,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }

  Widget _buildBottomTitle(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= widget.sets.length) {
      return const SizedBox.shrink();
    }

    final date = widget.sets[index].loggedAt;
    final formatter = DateFormat('M/d');

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        formatter.format(date),
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildLeftTitle(double value, TitleMeta meta) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        value.toInt().toString(),
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  List<LineTooltipItem?> _buildTooltipItems(List<LineBarSpot> touchedSpots) {
    return touchedSpots.map((spot) {
      final index = spot.spotIndex;
      if (index < 0 || index >= widget.sets.length) return null;

      final set = widget.sets[index];
      final dateStr = DateFormat('MMM d, yyyy').format(set.loggedAt);
      final weightStr = set.weight != null ? '${set.weight} lbs' : '-';
      final repsStr = set.reps != null ? '${set.reps} reps' : '-';

      return LineTooltipItem(
        '$dateStr\n$weightStr × $repsStr',
        const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(Colors.blue, 'Weight (lbs)', theme),
          const SizedBox(width: 24),
          _buildLegendItem(Colors.green, 'Reps', theme),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  double _getMinX() => 0;

  double _getMaxX() => (widget.sets.length - 1).toDouble().clamp(0, double.infinity);

  double _getMaxY() {
    double maxWeight = 0;
    double maxReps = 0;

    for (final set in widget.sets) {
      if (set.weight != null && set.weight! > maxWeight) {
        maxWeight = set.weight!;
      }
      if (set.reps != null && set.reps! > maxReps) {
        maxReps = set.reps!.toDouble();
      }
    }

    if (widget.showOverlay) {
      return (maxWeight > maxReps ? maxWeight : maxReps) * 1.2;
    }

    final max = widget.dataType == ChartDataType.weight ? maxWeight : maxReps;
    return max * 1.2;
  }

  double _calculateInterval() {
    final maxY = _getMaxY();
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    if (maxY <= 200) return 50;
    return 100;
  }

  double _calculateDateInterval() {
    final count = widget.sets.length;
    if (count <= 5) return 1;
    if (count <= 10) return 2;
    if (count <= 20) return 4;
    return (count / 5).ceilToDouble();
  }
}
