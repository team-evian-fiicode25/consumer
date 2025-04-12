import 'package:flutter/material.dart';
import 'expanded_transit_details.dart';

class TransitDetailsModal extends StatelessWidget {
  final List<dynamic> transitDetails;
  final dynamic currentTransitStep;
  final String? totalTime;

  const TransitDetailsModal({
    Key? key,
    required this.transitDetails,
    required this.currentTransitStep,
    required this.totalTime,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required List<dynamic> transitDetails,
    required dynamic currentTransitStep,
    required String? totalTime,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) {
          return TransitDetailsModal(
            transitDetails: transitDetails,
            currentTransitStep: currentTransitStep,
            totalTime: totalTime,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpandedTransitDetails(
      transitDetails: transitDetails,
      currentTransitStep: currentTransitStep,
      totalTime: totalTime,
      onClose: () => Navigator.of(context).pop(),
    );
  }
} 