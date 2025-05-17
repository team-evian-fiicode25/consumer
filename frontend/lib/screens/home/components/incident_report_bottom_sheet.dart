import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/incidents_service.dart';
import '../../../core/services/noise_alert_service.dart';

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
  final List<String> _incidentTypes = ["Accident", "Roadblock", "BadWeather", "Hazard", "Traffic", "Noise", "Other"];
  final Map<String, IconData> _incidentIcons = {
    "Accident": Icons.warning,
    "Roadblock": Icons.block,
    "BadWeather": Icons.cloud,
    "Hazard": Icons.report,
    "Traffic": Icons.traffic,
    "Noise": Icons.surround_sound,
    "Other": Icons.help_outline,
  };
  bool _isLoading = false;
  bool _isListening = false;
  int _remainingSeconds = 10;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    NoiseAlertService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isListening) {
      return _buildListeningUI();
    }
    
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

  Widget _buildListeningUI() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 20),
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
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Measuring Noise Level",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  _cancelNoiseMeasurement();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          SizedBox(height: 30),
          Container(
            height: 180,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.05),
                  ),
                ),
                PulsingMicIcon(),
              ],
            ),
          ),
          SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.graphic_eq, color: Colors.grey[600], size: 20),
              SizedBox(width: 8),
              Text(
                "Threshold: ${NoiseAlertService.noiseThreshold.toStringAsFixed(1)} dB",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 30),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  value: (10 - _remainingSeconds) / 10,
                ),
              ),
              Text(
                "${_remainingSeconds}s",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          SizedBox(height: 25),
          OutlinedButton.icon(
            onPressed: () {
              _cancelNoiseMeasurement();
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.cancel, color: Colors.red[400]),
            label: Text("Cancel Measurement"),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[400],
              side: BorderSide(color: Colors.red[200]!),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  void _cancelNoiseMeasurement() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    NoiseAlertService.stopListening();
  }

  String _getNoiseInterpretation(double decibels) {
    if (decibels < 30) return "Very quiet - Whisper";
    if (decibels < 40) return "Library, quiet suburb";
    if (decibels < 50) return "Quiet office";
    if (decibels < 60) return "Normal conversation";
    if (decibels < 70) return "Busy office";
    if (decibels < 80) return "Busy street, crowded restaurant";
    if (decibels < 90) return "Heavy traffic, factory machinery";
    if (decibels < 100) return "Construction site, motorcycle";
    if (decibels < 110) return "Rock concert, car horn";
    if (decibels < 120) return "Ambulance siren";
    return "Jet engine, fireworks - potential hearing damage";
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
    if (!mounted) return;
    
    setState(() { _isLoading = true; });
    
    try {
      if(_selectedIncidentType == "Noise") {
        bool hasPermission = await NoiseAlertService.checkAndRequestMicrophonePermission();
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Microphone permission required to detect noise"),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: "Settings",
                  onPressed: () async {
                    await openAppSettings();
                  },
                  textColor: Colors.white,
                ),
              )
            );
            setState(() { _isLoading = false; });
          }
          return;
        }
        
        if (mounted) {
          setState(() { 
            _isLoading = false;
            _isListening = true;
            _remainingSeconds = 10;
          });
        }
        
        _countdownTimer?.cancel();
        _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _remainingSeconds--;
            });
            
            if (_remainingSeconds <= 0) {
              timer.cancel();
            }
          } else {
            timer.cancel();
          }
        });
        
        NoiseAlertService.startNoiseDetection().then((result) async {
          _countdownTimer?.cancel();
          
          if (!mounted) return;
          
          final bool success = result['success'] ?? false;
          final bool isLoudEnough = result['isLoudEnough'] ?? false;
          final double avgValue = result['value'] ?? 0.0;
          final double maxValue = result['max_value'] ?? 0.0;
          final bool wasSimulated = result['simulated'] ?? false;
          
          Navigator.of(context).pop();
          
          if (!success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Could not detect noise. Please try again."),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              )
            );
            return;
          }
          
          if (isLoudEnough) {
            try {
              String noiseDescription = _descriptionController.text.trim().isEmpty 
                  ? 'Noise incident' 
                  : _descriptionController.text;
              
              String noiseInterpretation = _getNoiseInterpretation(avgValue);
              
              String reportText = "$noiseDescription\n"
                  "Measured noise: ${avgValue.toStringAsFixed(1)} dB avg (peak: ${maxValue.toStringAsFixed(1)} dB)${wasSimulated ? ' (estimated)' : ''}\n"
                  "Interpretation: $noiseInterpretation";
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Noise incident reported: ${avgValue.toStringAsFixed(1)} dB (${noiseInterpretation})"),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 5),
                  )
              );
              IncidentsService service = IncidentsService();
              final result = await service.reportIncident(
                widget.userID, 
                widget.locationWKT, 
                reportText, 
                "Noise"
              );
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error reporting incident: $e"),
                    backgroundColor: Colors.red,
                  )
                );
              }
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Noise level too low (${avgValue.toStringAsFixed(1)} dB - ${_getNoiseInterpretation(avgValue)}). Threshold: ${NoiseAlertService.noiseThreshold.toStringAsFixed(1)} dB"),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              )
            );
          }
        }).catchError((e) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error measuring noise: $e"),
                backgroundColor: Colors.red,
              )
            );
          }
        });
        
        return;
      }
      
      IncidentsService service = IncidentsService();
      await service.reportIncident(widget.userID, widget.locationWKT, _descriptionController.text, _selectedIncidentType);
      
      if (mounted) {
        Navigator.of(context).pop();
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final messenger = ScaffoldMessenger.of(context);
            messenger.hideCurrentSnackBar();
            messenger.showSnackBar(
              SnackBar(
                content: Text("Incident reported successfully"),
                backgroundColor: Colors.green.shade600,
                duration: Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(bottom: 10, left: 10, right: 10),
              )
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          )
        );
      }
    }
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

class PulsingMicIcon extends StatefulWidget {
  @override
  _PulsingMicIconState createState() => _PulsingMicIconState();
}

class _PulsingMicIconState extends State<PulsingMicIcon> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: (1.0 - _pulseAnimation.value) * 0.7,
              child: Container(
                width: 80 + (_pulseAnimation.value * 30),
                height: 80 + (_pulseAnimation.value * 30),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade300,
                ),
              ),
            ),
            Opacity(
              opacity: (1.0 - _pulseAnimation.value) * 0.5,
              child: Container(
                width: 70 + (_pulseAnimation.value * 40),
                height: 70 + (_pulseAnimation.value * 40),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade200,
                ),
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.mic,
                size: 30,
                color: Colors.blue,
              ),
            ),
          ],
        );
      },
    );
  }
}
