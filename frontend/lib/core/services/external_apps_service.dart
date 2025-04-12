import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';

class ExternalAppsService {
  static final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  
  static void _showMessage(String message) {
    try {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('MESSAGE: $message');
    }
  }

  static Future<bool> _openBoltAppStore() async {
    try {
      if (Platform.isAndroid) {
        return await launchUrl(
          Uri.parse('https://play.google.com/store/apps/details?id=ee.mtakso.client'),
          mode: LaunchMode.externalApplication
        );
      } else if (Platform.isIOS) {
        return await launchUrl(
          Uri.parse('https://apps.apple.com/app/bolt-fast-affordable-rides/id675033630'),
          mode: LaunchMode.externalApplication
        );
      }

      return false;
    } catch (e) {
      debugPrint('Error opening Bolt app store: $e');
      return false;
    }
  }
  
  static Future<bool> _openUberAppStore() async {
    try {
      if (Platform.isAndroid) {
        return await launchUrl(
          Uri.parse('https://play.google.com/store/apps/details?id=com.ubercab'),
          mode: LaunchMode.externalApplication
        );
      } else if (Platform.isIOS) {
        return await launchUrl(
          Uri.parse('https://apps.apple.com/app/uber/id368677368'),
          mode: LaunchMode.externalApplication
        );
      }

      return false;
    } catch (e) {
      debugPrint('Error opening Uber app store: $e');
      return false;
    }
  }

  static Future<bool> openRideOptionsWithFeedback(
    BuildContext context,
    LatLng destination, {
    LatLng? origin,
  }) async {
    bool appLaunched = false;

    final String? choice = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.directions_car, color: Colors.black54),
              SizedBox(width: 10),
              Text('Choose Ride Service', 
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRideOption(
                  context,
                  'Bolt',
                  'assets/icons/bolt_icon.png',
                  Colors.green,
                ),
                _buildRideOption(
                  context,
                  'Uber',
                  'assets/icons/uber_icon.png',
                  Colors.black,
                ),
                _buildRideOption(
                  context,
                  'Other Map Apps',
                  'assets/icons/maps_icon.png',
                  Colors.blue,
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.cancel, color: Colors.grey),
                  title: Text('Cancel'),
                  onTap: () {
                    Navigator.of(context).pop('cancel');
                  },
                ),
              ],
            ),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );

    if (choice == null || choice == 'cancel') {
      return false;
    }
    
    bool? launchResult = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _LaunchStatusDialog(
          choice: choice,
          destination: destination,
          origin: origin,
          onComplete: (result) {
            Navigator.of(context).pop(result);
          },
        );
      },
    );

    appLaunched = launchResult ?? false;
    
    return appLaunched;
  }

  static Widget _buildRideOption(
    BuildContext context,
    String title,
    String iconAsset,
    Color color,
  ) {
    return ListTile(
      leading: Icon(
        title == 'Bolt' ? Icons.bolt : 
        title == 'Uber' ? Icons.local_taxi : 
        Icons.map,
        color: color,
      ),
      title: Text(title),
      onTap: () {
        Navigator.of(context).pop(title.toLowerCase());
      },
    );
  }
}

class _LaunchStatusDialog extends StatefulWidget {
  final String choice;
  final LatLng destination;
  final LatLng? origin;
  final Function(bool) onComplete;

  const _LaunchStatusDialog({
    required this.choice,
    required this.destination,
    this.origin,
    required this.onComplete,
  });

  @override
  _LaunchStatusDialogState createState() => _LaunchStatusDialogState();
}

class _LaunchStatusDialogState extends State<_LaunchStatusDialog> {
  String status = 'Preparing to launch...';
  String details = '';
  bool isLoading = true;
  bool success = false;
  
  @override
  void initState() {
    super.initState();
    _launchApp();
  }
  
  Future<void> _launchApp() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      status = 'Launching ${widget.choice}...';
    });
    
    bool launchSuccessful = false;
    
    try {
      if (widget.choice.toLowerCase() == 'bolt') {
        setState(() {
          details = 'Opening Bolt app...';
        });
        
        final boltUri = Uri.parse('bolt://ride');
        try {
          launchSuccessful = await launchUrl(boltUri, mode: LaunchMode.externalApplication);
        } catch (e) {
          setState(() {
            details = 'Could not open Bolt app: ${e.toString()}';
          });
        }
        
        if (!launchSuccessful) {
          setState(() {
            status = 'Bolt app not installed';
            details = 'Opening app store...';
          });
          
          launchSuccessful = await ExternalAppsService._openBoltAppStore();
        }
      } 
      else if (widget.choice.toLowerCase() == 'uber') {
        setState(() {
          details = 'Opening Uber app...';
        });
        
        final uberUri = Uri.parse(
            'uber://?action=setPickup&dropoff[latitude]=${widget.destination.latitude}'
            '&dropoff[longitude]=${widget.destination.longitude}&pickup=my_location');
        
        try {
          launchSuccessful = await launchUrl(uberUri, mode: LaunchMode.externalApplication);
        } catch (e) {
          setState(() {
            details = 'Could not open Uber app: ${e.toString()}';
          });
        }
        
        if (!launchSuccessful) {
          setState(() {
            status = 'Uber app not installed';
            details = 'Opening app store...';
          });
          
          launchSuccessful = await ExternalAppsService._openUberAppStore();
        }
      }
      else if (widget.choice.toLowerCase() == 'other map apps') {
        setState(() {
          details = 'Opening maps app...';
        });
        
        try {
          final geoUri = Uri.parse('geo:${widget.destination.latitude},${widget.destination.longitude}'
              '?q=${widget.destination.latitude},${widget.destination.longitude}(Destination)');
          
          launchSuccessful = await launchUrl(geoUri, mode: LaunchMode.externalApplication);
          
          if (!launchSuccessful) {
            setState(() {
              status = 'No maps app found';
              details = 'Please install a maps application';
            });
          }
        } catch (e) {
          setState(() {
            details = 'Could not open maps app: ${e.toString()}';
          });
        }
      }
    } catch (e) {
      setState(() {
        status = 'Error occurred';
        details = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
        success = launchSuccessful;
      });
      
      await Future.delayed(const Duration(seconds: 1));
      
      widget.onComplete(launchSuccessful);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isLoading ? Icons.hourglass_top : 
            success ? Icons.check_circle : Icons.error,
            color: isLoading ? Colors.orange : 
                  success ? Colors.green : Colors.red,
          ),
          SizedBox(width: 14),
          Text(status),
        ],
      ),
      content: SizedBox(
        height: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(details),
          ],
        ),
      ),
    );
  }
} 