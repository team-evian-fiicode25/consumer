import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_ui/core/services/geo_location.dart';
import 'package:mobile_ui/core/services/uber_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  LatLng currentLocation = const LatLng(44.31302218631675, 23.833631876187884);
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    final location = await GeoLocationService.getCurrentLocation();
    if (location != null) {
      setState(() {
        currentLocation = location;
        isLoading = false;
      });
    } else {
      debugPrint('Could not fetch location, using default.');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: CameraPosition(target: currentLocation, zoom: 14.4746),
            onMapCreated: (controller) {
              // TODO (mihaescuvlad): Ivestigate controller caching
            },
            myLocationEnabled: true,
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            left: 16,
            top: 50,
            child: _buildMenuButton(theme),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      TextField(
                        style: TextStyle(color: theme.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Where to?',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.inputDecorationTheme.fillColor,
                        ),
                      ),
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Icon(
                            Icons.search,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildSavedPlace(theme, "Home", Icons.home, onTap: () => debugPrint("Home tapped")),
                        const SizedBox(width: 8),
                        _buildSavedPlace(theme, "Work", Icons.work, onTap: () => debugPrint("Work tapped")),
                        const SizedBox(width: 8),
                        _buildSavedPlace(theme, "Gym", Icons.fitness_center, onTap: () => debugPrint("Gym tapped")),
                        const SizedBox(width: 8),
                        _buildSavedPlace(theme, "Uber", Icons.car_rental, onTap: handleUber),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          icon: Icon(
            Icons.menu,
            color: theme.colorScheme.primary,
          ),
          onPressed: () {
            context.goNamed('settings');
          },
        ),
      ),
    );
  }

  Widget _buildSavedPlace(ThemeData theme, String name, IconData icon, {required VoidCallback onTap}) {
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: BorderSide(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: theme.colorScheme.primary.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(name, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }

  void handleUber() {
    final uberService = UberService();

    uberService.getProducts(
      latitude: currentLocation.latitude,
      longitude: currentLocation.longitude,
    );
  }

}
