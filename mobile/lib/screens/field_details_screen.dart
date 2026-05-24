import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/yield_service.dart';
import '../services/field_service.dart';
import 'add_field_screen.dart';

class FieldDetailsScreen extends StatefulWidget {
  final String fieldName;
  final LatLng? location;
  final int? backendFieldId;

  const FieldDetailsScreen({
    super.key,
    required this.fieldName,
    this.location,
    this.backendFieldId,
  });

  @override
  State<FieldDetailsScreen> createState() => _FieldDetailsScreenState();
}

class _FieldDetailsScreenState extends State<FieldDetailsScreen> {
  final YieldService _yieldService = YieldService();
  final FieldService _fieldService = FieldService();
  String _ndviValue = "Loading...";
  String _ndviPeak = "Loading...";
  String _ndviFinal = "Loading...";
  bool _isLoading = true;
  String? _error;
  String _moistureValue = "Loading...";
  bool _isLoadingMoisture = true;

  // NPK Recommendation
  Map<String, dynamic>? _recommendation;
  bool _isLoadingNPK = true;

  @override
  void initState() {
    super.initState();
    _fetchNDVI();
    _fetchIoTData();
    _fetchRecommendation();
  }

  Future<void> _fetchIoTData() async {
    try {
      final iotData = await _yieldService.getIoTData();
      if (iotData != null && mounted) {
        setState(() {
          _moistureValue = (iotData['moisture'] ?? 'N/A').toString();
          _isLoadingMoisture = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _moistureValue = "N/A";
          _isLoadingMoisture = false;
        });
      }
    }
  }

  Future<void> _fetchNDVI() async {
    if (widget.location == null) {
      setState(() {
        _ndviValue = "N/A";
        _ndviPeak = "N/A";
        _ndviFinal = "N/A";
        _isLoading = false;
      });
      return;
    }

    try {
      final ndviData = await _yieldService.getNDVI(
        widget.location!.latitude,
        widget.location!.longitude,
      );
      setState(() {
        if (ndviData != null) {
          _ndviValue = (ndviData['ndvi_flowering'] ?? ndviData['mean'] ?? 'N/A')
              .toString();
          _ndviPeak = (ndviData['ndvi_peak'] ?? ndviData['max'] ?? 'N/A')
              .toString();
          _ndviFinal =
              (ndviData['ndvi_veg_slope'] ?? ndviData['final'] ?? 'N/A')
                  .toString();
        } else {
          _ndviValue = "N/A";
          _ndviPeak = "N/A";
          _ndviFinal = "N/A";
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchRecommendation() async {
    int? fieldId = widget.backendFieldId;

    // If no backend ID stored locally, look up from backend by name
    if (fieldId == null) {
      try {
        final fields = await _fieldService.getFields();
        if (fields != null) {
          for (final f in fields) {
            final backendName = f['name']?.toString() ?? '';
            // Match exact name, or if the Hive name contains the backend name
            // e.g. "Soyabean (Field 3)" contains "Field 3"
            if (backendName == widget.fieldName ||
                widget.fieldName.contains(backendName)) {
              fieldId = f['id'] as int?;
              break;
            }
          }
        }
      } catch (_) {}
    }

    if (fieldId == null) {
      setState(() => _isLoadingNPK = false);
      return;
    }
    try {
      // Extract crop name from field name (e.g. "Soyabean (Field 3)" -> "Soyabean")
      final cropName = widget.fieldName.split('(').first.trim();
      final data = await _fieldService.getFieldRecommendation(fieldId, crop: cropName);
      if (mounted) {
        setState(() {
          _recommendation = data;
          _isLoadingNPK = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingNPK = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.fieldName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NPK Recommendation Card
            if (_isLoadingNPK)
              _buildLoadingCard('Fertilizer Recommendation')
            else if (_recommendation != null)
              _buildNPKCard(),

            if (_recommendation != null || _isLoadingNPK)
              const SizedBox(height: 16),

            // NDVI Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3E3E3E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.satellite_alt,
                        color: Colors.white70,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Satellite Health (NDVI)',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        _isLoading ? "..." : "$_ndviValue %",
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00E676)),
                        ),
                        child: const Text(
                          'Healthy',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNdviStat(
                        'Peak NDVI',
                        _isLoading ? "..." : _ndviPeak,
                      ),
                      _buildNdviStat(
                        'Final NDVI',
                        _isLoading ? "..." : _ndviFinal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Source : Live Satellite Feed',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Moisture Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3E3E3E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sensors, color: Colors.white70, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Moisture Detected from Sensor',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        _isLoadingMoisture ? "..." : "$_moistureValue %",
                        style: const TextStyle(
                          color: Color(0xFF00E676),
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E676).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF00E676)),
                        ),
                        child: const Text(
                          'Good Moisture',
                          style: TextStyle(
                            color: Color(0xFF00E676),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Map
            SizedBox(
              height: 200,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: widget.location == null
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            "Location not available.",
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: widget.location!,
                            initialZoom: 15.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.mobile',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: widget.location!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddFieldScreen(
                            fieldName: widget.fieldName,
                            existingLocation: widget.location,
                          ),
                        ),
                      );
                      if (result != null && context.mounted) {
                        Navigator.pop(context, result);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF5350)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Edit Field',
                      style: TextStyle(color: Color(0xFFEF5350), fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF3E3E3E),
                          title: const Text(
                            "Delete Field",
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Text(
                            "Are you sure you want to delete this field?",
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        Navigator.pop(context, {'delete': true});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF5350),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Delete Field',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNPKCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3E3E3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.spa, color: Color(0xFFC5E1A5), size: 20),
              SizedBox(width: 8),
              Text(
                'Fertilizer Recommendation',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNPKItem(
                'N',
                _recommendation!['recommended_N'],
                const Color(0xFF42A5F5),
              ),
              _buildNPKItem(
                'P',
                _recommendation!['recommended_P'],
                const Color(0xFFFF7043),
              ),
              _buildNPKItem(
                'K',
                _recommendation!['recommended_K'],
                const Color(0xFFAB47BC),
              ),
            ],
          ),
          if (_recommendation!['target_yield'] != null) ...[
            const SizedBox(height: 12),
            Text(
              'Target Yield: ${_recommendation!['target_yield']} t/ha  |  Crop: ${_recommendation!['crop'] ?? '-'}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNPKItem(String label, dynamic value, Color color) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Center(
            child: Text(
              value?.toStringAsFixed(1) ?? 'N/A',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const Text(
          'kg/ha',
          style: TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildNdviStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3E3E3E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
