import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/incidents_service.dart';

class IncidentReportBottomSheet extends StatefulWidget {
  final String userID;
  final String locationWKT;
  const IncidentReportBottomSheet({
    Key? key,
    required this.userID,
    required this.locationWKT,
  }) : super(key: key);

  @override
  _IncidentReportBottomSheetState createState() => _IncidentReportBottomSheetState();
}

class _IncidentReportBottomSheetState extends State<IncidentReportBottomSheet> {
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedIncidentType = "Accident";
  final List<String> _incidentTypes = ["Accident", "Roadblock", "BadWeather", "Hazard", "Traffic", "Other"];
  final Map<String, IconData> _incidentIcons = {
    "Accident": Icons.warning,
    "Roadblock": Icons.block,
    "BadWeather": Icons.cloud,
    "Hazard": Icons.report,
    "Traffic": Icons.traffic,
    "Other": Icons.help_outline,
  };
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 12, left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 40,
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Report Incident",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Colors.grey[600],
                  size: 28,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          SizedBox(height: 16),
          buildIncidentTypeSelector(),
          SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Description",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          SizedBox(height: 16),
          _isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
            onPressed: _submitIncident,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text("Submit", style: TextStyle(fontSize: 16)),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget buildIncidentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Incident Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _incidentTypes.map((type) {
            bool isSelected = (_selectedIncidentType == type);
            return InkWell(
              onTap: () => setState(() { _selectedIncidentType = type; }),
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueAccent : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _incidentIcons[type]!,
                      size: 28,
                      color: isSelected ? Colors.white : Colors.black54,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    type,
                    style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _submitIncident() async {
    setState(() { _isLoading = true; });
    try {
      IncidentsService service = IncidentsService();
      await service.reportIncident(widget.userID, widget.locationWKT, _descriptionController.text, _selectedIncidentType);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Incident reported successfully")));
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() { _isLoading = false; });
  }
}

Future<void> showIncidentReportBottomSheet(BuildContext context, String userID, LatLng location) {
  final locationWKT = "POINT(${location.longitude} ${location.latitude})";
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => IncidentReportBottomSheet(userID: userID, locationWKT: locationWKT),
  );
}
