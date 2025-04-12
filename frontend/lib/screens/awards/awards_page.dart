import 'package:flutter/material.dart';

import '../widgets/back_button.dart' show CustomBackButton;

class AwardsPage extends StatelessWidget {
  const AwardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // TODO (mihaescuvlad): Request data from Mongo
    const String username = 'testing_account';
    const int userXp = 9500;
    const int contributions = 47;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awards'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: CustomBackButton(path: "settings"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildUserHeader(context, username, userXp),
            _buildContributions(context, contributions),
            _buildBadgesList(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildUserHeader(BuildContext context, String username, int xp) {
    final theme = Theme.of(context);
    final rank = _getUserRank(xp);
    final rankColor = _getRankColor(rank);
    
    return Container(
      padding: const EdgeInsets.all(20),
      color: theme.colorScheme.primary.withOpacity(0.05),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          username,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.verified,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: rankColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: rankColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getRankIcon(rank),
                            size: 16,
                            color: rankColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            rank,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: rankColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Experience Points',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _getXpProgress(xp),
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  color: rankColor,
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 10,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$xp XP',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getNextRankText(xp),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContributions(BuildContext context, int contributions) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contributions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Contributions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'You\'ve helped the community $contributions times',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  '$contributions',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBadgesList(BuildContext context) {
    final theme = Theme.of(context);
    
    // TODO (mihaescuvlad): Request data from Mongo
    final badges = [
      {
        'name': 'Early Adopter',
        'description': 'Joined the platform in its early days',
        'icon': Icons.access_time,
        'color': Colors.blue,
        'earned': true,
      },
      {
        'name': 'Ride Enthusiast',
        'description': 'Completed more than 10 rides',
        'icon': Icons.directions_car,
        'color': Colors.green,
        'earned': true,
      },
      {
        'name': 'Walking Enthusiast',
        'description': 'Completed more than 10 rides on foot',
        'icon': Icons.directions_walk,
        'color': Colors.amber,
        'earned': true,
      },
      {
        'name': 'Bike Enthusiast',
        'description': 'Completed 10 rides on a bike',
        'icon': Icons.pedal_bike,
        'color': Colors.orange,
        'earned': false,
      },
      {
        'name': 'Night Owl',
        'description': 'Completed 10 rides between 10 PM and 5 AM',
        'icon': Icons.nightlight_round,
        'color': Colors.deepPurple,
        'earned': false,
      },
      {
        'name': 'Long Distance Traveler',
        'description': 'Traveled more than 1000 kilometers on foot',
        'icon': Icons.map,
        'color': Colors.teal,
        'earned': false,
      },
    ];
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Badges',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...badges.map((badge) => _buildBadgeItem(context, badge)),
        ],
      ),
    );
  }
  
  Widget _buildBadgeItem(BuildContext context, Map<String, dynamic> badge) {
    final theme = Theme.of(context);
    final bool earned = badge['earned'] as bool;
    final Color badgeColor = earned ? badge['color'] as Color : Colors.grey;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                badge['icon'] as IconData,
                color: badgeColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        badge['name'] as String,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (earned) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  Text(
                    badge['description'] as String,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (!earned)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onBackground.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Locked',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _getUserRank(int xp) {
    if (xp >= 12000 && xp <= 20000) return 'Chivalric';
    if (xp >= 8000 && xp <= 11999) return 'Noble';
    if (xp >= 4000 && xp <= 7999) return 'Good';
    if (xp >= 1000 && xp <= 3999) return 'Friendly';
    if (xp >= 0 && xp <= 999) return 'Neutral';
    if (xp >= -3999 && xp <= -1) return 'Aggressive';
    if (xp >= -7999 && xp <= -4000) return 'Fraudulent';
    if (xp >= -11999 && xp <= -8000) return 'Malicious';
    return 'Unknown';
  }
  
  Color _getRankColor(String rank) {
    switch (rank) {
      case 'Chivalric':
        return Colors.deepPurple;
      case 'Noble':
        return Colors.indigo;
      case 'Good':
        return Colors.blue;
      case 'Friendly':
        return Colors.teal;
      case 'Neutral':
        return Colors.grey;
      case 'Aggressive':
        return Colors.amber;
      case 'Fraudulent':
        return Colors.deepOrange;
      case 'Malicious':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getRankIcon(String rank) {
    switch (rank) {
      case 'Chivalric':
        return Icons.military_tech;
      case 'Noble':
        return Icons.diamond;
      case 'Good':
        return Icons.thumb_up;
      case 'Friendly':
        return Icons.sentiment_satisfied;
      case 'Neutral':
        return Icons.person;
      case 'Aggressive':
        return Icons.warning;
      case 'Fraudulent':
        return Icons.block;
      case 'Malicious':
        return Icons.dangerous;
      default:
        return Icons.help;
    }
  }
  
  double _getXpProgress(int xp) {
    if (xp >= 12000 && xp <= 20000) {
      return (xp - 12000) / (20000 - 12000);
    }
    if (xp >= 8000 && xp <= 11999) {
      return (xp - 8000) / (11999 - 8000);
    }
    if (xp >= 4000 && xp <= 7999) {
      return (xp - 4000) / (7999 - 4000);
    }
    if (xp >= 1000 && xp <= 3999) {
      return (xp - 1000) / (3999 - 1000);
    }
    if (xp >= 0 && xp <= 999) {
      return xp / 999;
    }
    if (xp >= -3999 && xp <= -1) {
      return (xp + 3999) / (3999 - 1);
    }
    if (xp >= -7999 && xp <= -4000) {
      return (xp + 7999) / (7999 - 4000);
    }
    if (xp >= -11999 && xp <= -8000) {
      return (xp + 11999) / (11999 - 8000);
    }
    return 0;
  }
  
  String _getNextRankText(int xp) {
    if (xp >= 12000 && xp < 20000) {
      return '${20000 - xp} XP to max rank';
    }
    if (xp >= 8000 && xp < 11999) {
      return '${12000 - xp} XP to Chivalric';
    }
    if (xp >= 4000 && xp < 7999) {
      return '${8000 - xp} XP to Noble';
    }
    if (xp >= 1000 && xp < 3999) {
      return '${4000 - xp} XP to Good';
    }
    if (xp >= 0 && xp < 999) {
      return '${1000 - xp} XP to Friendly';
    }
    return '';
  }
}