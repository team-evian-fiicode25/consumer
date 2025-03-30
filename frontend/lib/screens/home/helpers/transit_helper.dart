import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TransitHelper {
  static void updateCurrentTransitStep(
    List<Map<String, dynamic>> transitDetails,
    String transportMode,
    Function(Map<String, dynamic>?) onUpdate,
  ) {
    if (transitDetails.isEmpty || transportMode != "transit") {
      onUpdate(null);
      return;
    }
    
    if (transitDetails.isNotEmpty) {
      onUpdate(transitDetails[0]);
    }
  }

  static void checkForArrivalAtTransitStop({
    required LatLng currentLocation,
    required Set<Circle> transitStops,
    required List<Map<String, dynamic>> transitDetails,
    required Map<String, dynamic>? currentTransitStep,
    required double Function(LatLng, LatLng) calculateDistanceInMeters,
    required Function(Circle) onBoardTransitVehicle,
    required Function() onCheckArrivedAtNextStop,
  }) {
    if (transitStops.isEmpty || transitDetails.isEmpty) return;
    
    if (currentTransitStep != null && currentTransitStep['isOnboard'] == true) {
      onCheckArrivedAtNextStop();
      return;
    }
    
    for (var stop in transitStops) {
      final double distanceToStop = calculateDistanceInMeters(
        currentLocation, 
        stop.center
      );
      
      if (distanceToStop <= 20) {
        onBoardTransitVehicle(stop);
        break;
      }
    }
  }

  static void boardTransitVehicle({
    required Circle boardingStop,
    required List<Map<String, dynamic>> transitDetails,
    required BuildContext context,
    required Function(Set<Circle> Function(Set<Circle>)) updateTransitStops,
    required Function(Map<String, dynamic>?) updateCurrentTransitStep,
    required String Function(String) findNextStopId,
  }) {
    updateTransitStops((stops) {
      stops.remove(boardingStop);
      return stops;
    });
    
    if (transitDetails.isNotEmpty) {
      Map<String, dynamic> currentSegment = Map<String, dynamic>.from(transitDetails[0]);
      
      updateCurrentTransitStep({
        ...currentSegment,
        'isOnboard': true,
        'nextStopId': findNextStopId(boardingStop.circleId.value),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Boarded ${transitDetails[0]['line']} ${transitDetails[0]['type']}'),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  static void checkIfArrivedAtNextStop({
    required Map<String, dynamic>? currentTransitStep,
    required Set<Circle> transitStops,
    required LatLng currentLocation,
    required String lastDisplayedStopId,
    required List<Map<String, dynamic>> transitDetails,
    required BuildContext context,
    required double Function(LatLng, LatLng) calculateDistanceInMeters,
    required String Function(String) findNextStopId,
    required Function(String) updateLastDisplayedStopId,
    required Function(Set<Circle> Function(Set<Circle>)) updateTransitStops,
    required Function(List<Map<String, dynamic>> Function(List<Map<String, dynamic>>)) updateTransitDetails,
    required Function(Map<String, dynamic>?) updateCurrentTransitStep,
    required Function() updateRoutePolyline,
  }) {
    if (currentTransitStep == null || transitStops.isEmpty) return;
    
    final String nextStopId = currentTransitStep['nextStopId']?.toString() ?? '';
    if (nextStopId.isEmpty) return;
    
    Circle? nextStop;
    for (var stop in transitStops) {
      if (stop.circleId.value == nextStopId) {
        nextStop = stop;
        break;
      }
    }
    
    if (nextStop == null) return;
    
    final double distanceToStop = calculateDistanceInMeters(
      currentLocation, 
      nextStop.center
    );
    
    if (lastDisplayedStopId != nextStopId && distanceToStop < 50) {
      updateLastDisplayedStopId(nextStopId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Approaching next stop on ${currentTransitStep['line']} ${currentTransitStep['type']}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.blue.shade700,
        ),
      );
    }
    
    if (distanceToStop <= 25) {
      updateTransitStops((stops) {
        stops.remove(nextStop);
        return stops;
      });
      
      var hasMoreStops = false;
      var nextNextStopId = findNextStopId(nextStopId);
      
      for (var stop in transitStops) {
        if (stop.circleId.value == nextNextStopId) {
          hasMoreStops = true;
          break;
        }
      }
      
      if (hasMoreStops) {
        Map<String, dynamic> updatedStep = Map<String, dynamic>.from(currentTransitStep);
        updatedStep['nextStopId'] = nextNextStopId;
        updatedStep['previousStopId'] = nextStopId;
        
        updateCurrentTransitStep(updatedStep);
        updateLastDisplayedStopId('');
      } else {
        if (transitDetails.isNotEmpty) {
          updateTransitDetails((details) {
            if (details.isNotEmpty) {
              details.removeAt(0);
            }
            return details;
          });
          
          if (transitDetails.isNotEmpty) {
            Map<String, dynamic> nextSegment = Map<String, dynamic>.from(transitDetails[0]);
            nextSegment['isOnboard'] = false;
            
            updateCurrentTransitStep(nextSegment);
            updateLastDisplayedStopId('');
          } else {
            updateCurrentTransitStep(null);
            updateRoutePolyline();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You\'ve reached your final transit stop. Continue walking to your destination.'),
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      }
      
      if (currentTransitStep.containsKey('isOnboard') && 
          currentTransitStep['isOnboard'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transfer to ${currentTransitStep['line']} ${currentTransitStep['type']}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } 
    else if (currentTransitStep.containsKey('previousStopId')) {
      String nextNextStopId = findNextStopId(nextStopId);
      Circle? nextNextStop;
      
      for (var stop in transitStops) {
        if (stop.circleId.value == nextNextStopId) {
          nextNextStop = stop;
          break;
        }
      }
      
      if (nextNextStop != null) {
        double distanceToNextNextStop = calculateDistanceInMeters(
          currentLocation, 
          nextNextStop.center
        );
        
        if (distanceToNextNextStop < distanceToStop) {
          updateTransitStops((stops) {
            stops.remove(nextStop);
            return stops;
          });
          
          Map<String, dynamic> updatedStep = Map<String, dynamic>.from(currentTransitStep);
          updatedStep['nextStopId'] = nextNextStopId;
          updatedStep['previousStopId'] = nextStopId;
          
          updateCurrentTransitStep(updatedStep);
          updateLastDisplayedStopId('');
        }
      }
    }
  }

  static String findNextStopId(String currentStopId) {
    final RegExp regex = RegExp(r'transit_stop_(\d+)');
    final match = regex.firstMatch(currentStopId);
    
    if (match != null && match.groupCount >= 1) {
      final String? numberStr = match.group(1);
      if (numberStr != null) {
        int currentStopNumber = int.tryParse(numberStr) ?? 0;
        return 'transit_stop_${currentStopNumber + 1}';
      }
    }
    
    return '';
  }
}