import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_config.dart';
import 'services/machine_service.dart';

class MachineOverviewScreen extends StatefulWidget {
  const MachineOverviewScreen({super.key});

  @override
  State<MachineOverviewScreen> createState() => _MachineOverviewScreenState();
}

class _MachineOverviewScreenState extends State<MachineOverviewScreen> {
  Map<String, dynamic>? overviewData;
  bool isLoading = true;
  String errorMessage = '';
  Timer? refreshTimer;
  DateTime? lastRefreshTime;

  @override
  void initState() {
    super.initState();
    fetchOverview();
    startAutoRefresh();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  void startAutoRefresh() {
    refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      fetchOverview(showLoader: false);
    });
  }

  Future<void> fetchOverview({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
    }
    try {
      final data = await MachineService.getMachineOverview(AppConfig.defaultMachineId);
      setState(() {
        overviewData = data;
        isLoading = false;
        lastRefreshTime = DateTime.now();
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading && overviewData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F4F6),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage.isNotEmpty && overviewData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Center(child: Text(errorMessage, style: const TextStyle(color: Colors.red))),
      );
    }

    final data = overviewData;
    final trend = data?['trend'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('TESTING QUIK IoT'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildTrendChartCard(trend),
                  const SizedBox(height: 24),
                  _buildWelderAssignmentCard(),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildTopMetricsCard(),
                  const SizedBox(height: 24),
                  _buildTemperatureCard(data),
                  const SizedBox(height: 24),
                  _buildWelderIdentificationCard(data),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= Helpers =================

  Widget _buildTrendChartCard(List<dynamic> trend) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,4))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildLegendItem(Colors.teal, 'Current A'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.blue, 'Voltage V'),
            ],
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 2.0,
            child: _buildTrendChart(trend),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2433),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  child: const Text('Set Current'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {},
                  child: const Text('Reset', style: TextStyle(color: Colors.black87)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<dynamic> trend) {
    List<FlSpot> currentSpots = [];
    List<FlSpot> voltageSpots = [];

    for (int i = 0; i < (trend.isEmpty ? 20 : trend.length); i++) {
      double x = (i+1).toDouble();
      if (trend.isEmpty) {
        currentSpots.add(FlSpot(x, 0));
        voltageSpots.add(FlSpot(x,0));
      } else {
        final row = trend[i] as Map<String,dynamic>;
        currentSpots.add(FlSpot(x, (row['current'] ?? 0).toDouble()));
        voltageSpots.add(FlSpot(x, (row['voltage'] ?? 0).toDouble()*4));
      }
    }

    double maxXValue = trend.isEmpty ? 20 : trend.length.toDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 400,
        minX: 1,
        maxX: maxXValue,
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 100, reservedSize: 40)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 100,
              getTitlesWidget: (value, _) => Text(
                  (value / 4).toInt().toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.blue)),
            ),
          ),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 5)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: currentSpots,
            isCurved: true,
            color: Colors.teal,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: voltageSpots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text){
    return Row(
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildWelderAssignmentCard(){
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,4))],
      ),
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          const Text('Welder Assignment', style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTextField(Icons.person_outline,'Welder Name'),
          const SizedBox(height: 16),
          _buildTextField(Icons.badge_outlined,'Employee Code'),
        ],
      ),
    );
  }

  Widget _buildTopMetricsCard(){
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,4))],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children:[
          _buildMetricBox('0'),
          _buildMetricBox('0'),
          _buildMetricBox('0'),
        ],
      ),
    );
  }

  Widget _buildTemperatureCard(Map<String,dynamic>? data){
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,4))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          const Text('Temperature', style: TextStyle(fontSize:16, fontWeight: FontWeight.bold)),
          const SizedBox(height:16),
          _buildTemperatureRow('Trafo Core Temp',data?['trafoCoreTemperature']??0.0),
          const SizedBox(height:12),
          _buildTemperatureRow('IGBT Temp',data?['igbtTemperature']??0.0),
          const SizedBox(height:12),
          _buildTemperatureRow('Heat Sync Temp',data?['heatSyncTemperature']??0.0),
        ],
      ),
    );
  }

  Widget _buildWelderIdentificationCard(Map<String,dynamic>? data){
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,4))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          const Text('Welder Identification (RFID)', style: TextStyle(fontSize:16, fontWeight: FontWeight.bold)),
          const SizedBox(height:16),
          _buildInfoRow('RFID Card','RFID-000127'),
          const SizedBox(height:12),
          _buildInfoRow('Welder Name','Mohd. Arif'),
        ],
      ),
    );
  }

  Widget _buildTextField(IconData icon, String hint){
    return TextField(
      decoration: InputDecoration(
        prefixIcon: Icon(icon,color: Colors.grey.shade600),
        hintText: hint,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical:16),
      ),
    );
  }

  Widget _buildMetricBox(String value){
    return Container(
      width:80, height:80, alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(value, style: const TextStyle(fontSize:24, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTemperatureRow(String label,double temp){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:[
        Text(label, style: const TextStyle(fontSize:14)),
        Text('${temp.toStringAsFixed(1)} °C', style: const TextStyle(fontSize:14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildInfoRow(String label,String value){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:[
        Text(label, style: const TextStyle(fontSize:14)),
        Text(value, style: const TextStyle(fontSize:14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}