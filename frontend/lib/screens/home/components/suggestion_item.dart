import 'package:flutter/material.dart';
import '../../../core/services/maps_service.dart';

class SuggestionItem extends StatelessWidget {
  final PlaceSuggestion suggestion;
  final VoidCallback onTap;

  const SuggestionItem({
    Key? key,
    required this.suggestion,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.place, color: Colors.blue),
      title: Text(
        suggestion.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _buildSubtitle(),
      trailing: suggestion.distance != null
          ? Chip(
              label: Text(
                suggestion.distance!,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              backgroundColor: Colors.grey[200],
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget? _buildSubtitle() {
    if (suggestion.duration != null) {
      return Row(
        children: [
          Icon(
            Icons.directions_car,
            size: 14,
            color: Colors.grey[600],
          ),
          SizedBox(width: 4),
          Text(
            suggestion.duration!,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      );
    }
    return null;
  }
} 