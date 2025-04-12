import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/maps_service.dart';
import 'components/transit_details_card.dart';
import 'components/transport_mode_options.dart';
import 'components/navigation_controls.dart';
import 'components/destination_shortcuts.dart';
import 'components/destination_search_bar.dart';
import 'helpers/route_helper.dart';
import 'helpers/map_ui_helper.dart';
import 'helpers/state_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> _mapController = Completer();
  final MapsService _mapsService = MapsService();

  late StateManager _stateManager;
  late MapState _state;

  @override
  void initState() {
    super.initState();

    _state = MapState(
      currentLocation: const LatLng(44.31302218631675, 23.833631876187884),
      transportMode: "driving",
      isNavigating: false,
      isFollowing: true,
      isLoading: true,
      polylines: {},
      markers: {},
      transitStops: {},
      userLocationMarker: {},
      transitDetails: [],
    );

    _stateManager = StateManager(
      initialState: _state,
      onStateUpdate: _onStateUpdate,
      mapsService: _mapsService,
      context: context,
    );

    _initialize();
  }

  void _onStateUpdate(MapState newState) {
    if (mounted) {
      setState(() {
        _state = newState;
      });
    }
  }

  Future<void> _initialize() async {
    _stateManager.registerCameraCallbacks(
      animateCameraTo: _animateCameraTo,
      followUser: (location) async {
        try {
          final GoogleMapController controller = await _mapController.future;
          controller.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: location,
              zoom: await controller.getZoomLevel(),
            ),
          ));
        } catch (e) {
          debugPrint('Error following user: $e');
        }
      },
    );

    await _stateManager.initialize();
  }

  Future<void> _animateCameraTo(LatLng location, {double zoom = 16}) async {
    if (!mounted) return;

    try {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: location, zoom: zoom),
      ),
    );
    } catch (e) {
      debugPrint('Error animating camera: $e');
    }
  }

  Future<void> _toggleNavigation() async {
    if (mounted) {
      setState(() {});

      _stateManager.toggleNavigation();

      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _onSearchPressed() async {
    if (!mounted) return;

    final result = await RouteHelper.searchAndSelectDestination(
      context,
      _mapsService,
      _state.currentLocation,
    );

    if (!mounted) return;

    if (result != null) {
      _stateManager.setDestination(result);
      await _animateCameraTo(result);
    }
  }

  void _onShortcutPressed(LatLng location) async {
    if (!mounted) return;

    _stateManager.setDestination(location);
    await _animateCameraTo(location);
  }

  void _clearDestinationAndRoutes() {
    _stateManager.clearDestination();

    if (mounted) {
      setState(() {});
    }
  }

  void _onStyleLoaded() {
    if (mounted) {
      setState(() {});
    }

    _mapController.future.then((controller) {
      if (mounted) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                _state.currentLocation.latitude,
                _state.currentLocation.longitude,
              ),
              zoom: 16,
            ),
          ),
        );
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_mapController.isCompleted) {
      _mapController.complete(controller);
      if (mounted) {
        _onStyleLoaded();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    final bool hasTransitDetails = _state.isNavigating &&
                                 _state.transportMode == "transit" &&
                                 _state.transitDetails.isNotEmpty;
    final double minBottomPadding = hasTransitDetails ? 160 : 140;

    final double bottomSheetHeight = _calculateBottomSheetHeight(
      hasDestination: _state.destination != null,
      isNavigating: _state.isNavigating,
      hasTransitDetails: hasTransitDetails,
      safeAreaBottom: safeAreaBottom,
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildMap(theme, minBottomPadding),

          if (_state.isLoading && _state.destination != null && _state.polylines.isEmpty)
            MapUIHelper.buildLoadingIndicator(context),

          Positioned(
            left: 16,
            top: 50,
            child: _buildMenuButton(theme),
          ),

          _buildMyLocationButton(theme, bottomSheetHeight),

          _buildNavigationBottomSheet(theme),
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
            color: Colors.black.withAlpha(51),
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

  double _calculateBottomSheetHeight({
    required bool hasDestination,
    required bool isNavigating,
    required bool hasTransitDetails,
    required double safeAreaBottom,
  }) {
    if (!hasDestination) {
      return 160 + safeAreaBottom;
    }

    if (isNavigating) {
      return hasTransitDetails
          ? 240 + safeAreaBottom
          : 150 + safeAreaBottom;
    }

    return 410 + safeAreaBottom;
  }

  Widget _buildMap(ThemeData theme, double minBottomPadding) {
    return Positioned.fill(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          _stateManager.updateState((state) => state.copyWith(
            isFollowing: false,
          ));
        },
        child: GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition:
          CameraPosition(target: _state.currentLocation, zoom: 14.4746),
          onMapCreated: _onMapCreated,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: MapUIHelper.getFilteredMarkers(_state.markers),
          circles: _state.userLocationMarker.union(_state.transitStops),
          polylines: _state.polylines,
          padding: EdgeInsets.only(bottom: minBottomPadding),
        ),
      ),
    );
  }

  Widget _buildMyLocationButton(ThemeData theme, double bottomSheetHeight) {
    return MapUIHelper.buildMyLocationButton(
      context,
      isFollowing: _state.isFollowing,
      bottomOffset: bottomSheetHeight + 30,
      onPressed: () async {
        _stateManager.updateState((state) => state.copyWith(
          isFollowing: true,
        ));
        await _animateCameraTo(_state.currentLocation, zoom: 18);
      },
    );
  }

  Widget _buildNavigationBottomSheet(ThemeData theme) {
    final bool hasTransitDetails = _state.isNavigating &&
                               _state.transportMode == "transit" &&
                               _state.transitDetails.isNotEmpty;

    final stateKey = ValueKey('navState:${_state.isNavigating}:dest:${_state.destination != null}');

    return AnimatedSwitcher(
      key: ValueKey('bottom_sheet_switcher_${_state.isNavigating}_${_state.destination != null}'),
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(animation),
            child: child
          ),
      child: KeyedSubtree(
        key: stateKey,
        child: _state.destination != null
            ? _buildDestinationSheet(theme, hasTransitDetails)
            : _buildFixedSheet(theme),
      ),
    );
  }

  Widget _buildDestinationSheet(ThemeData theme, bool hasTransitDetails) {
    final String keyString = "destination_sheet_${_state.isNavigating ? 'active' : 'inactive'}_${_state.transportMode}";
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      key: ValueKey(keyString),
            alignment: Alignment.bottomCenter,
                  child: Container(
        width: screenWidth,
                    decoration: BoxDecoration(
          color: theme.colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
              color: Colors.black.withAlpha(30),
                          blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, -3),
                        ),
                      ],
                    ),
        child: SafeArea(
          top: false,
          bottom: true,
          maintainBottomViewPadding: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 40,
                height: 4,
                            decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                child: Row(
                          children: [
                    if (!_state.isNavigating)
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _clearDestinationAndRoutes,
                        tooltip: 'Clear destination',
                        iconSize: 22,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    Expanded(
                      child: DestinationSearchBar(
                        key: ValueKey("destination_search_${_state.isNavigating ? 'active' : 'inactive'}"),
                        isNavigating: _state.isNavigating,
                        onSearchPressed: _onSearchPressed,
                        onNavigationStop: null,
                      ),
                            ),
                          ],
                        ),
              ),

              Builder(builder: (context) {
                final shouldShowOptions = _state.destination != null && !_state.isNavigating;

                return shouldShowOptions
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildTransportOptions(),
                    )
                  : const SizedBox(height: 8);
              }),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: NavigationControls(
                  isNavigating: _state.isNavigating,
                  distance: _state.distance,
                  duration: _state.duration,
                  transportMode: _state.transportMode,
                  transportColors: _stateManager.transportColors,
                  onNavigationToggle: _toggleNavigation,
                  onNavigationStop: _state.isNavigating ? _clearDestinationAndRoutes : null,
                  onUpdateDistanceAndTime: () {
                    _stateManager.updateDistanceAndTime();
                  },
                ),
              ),

              if (_state.isNavigating && _state.transportMode == "transit" && _state.transitDetails.isNotEmpty)
                TransitDetailsCard(
                  transitDetails: _state.transitDetails,
                  currentTransitStep: _getCurrentTransitStep(),
                  duration: _state.duration,
                  transitColor: _stateManager.transportColors["transit"] ?? Colors.purple.shade700,
                ),

              if (!_state.isNavigating)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: DestinationShortcuts(
                    onShortcutSelected: _onShortcutPressed,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFixedSheet(ThemeData theme) {
    return Container(
      key: const ValueKey("fixedSheet"),
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(40),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DestinationSearchBar(
                isNavigating: false,
                onSearchPressed: _onSearchPressed,
                onNavigationStop: null,
              ),

              DestinationShortcuts(
                onShortcutSelected: _onShortcutPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransportOptions() {
    return TransportModeOptions(
      currentMode: _state.transportMode,
      transportColors: _stateManager.transportColors,
      onModeSelected: _stateManager.updateTransportMode,
      distanceInMeters: _state.destination != null && _state.distance != null ?
          _parseDistance(_state.distance!) : 0,
      availableModes: _stateManager.availableModes,
      modeEstimates: _stateManager.modeEstimates,
    );
  }

  double _parseDistance(String distanceText) {
    try {
      if (distanceText.contains('km')) {
        final kmValue = double.tryParse(
          distanceText.replaceAll('km', '').trim()
        ) ?? 0.0;
        return kmValue * 1000;
      } else if (distanceText.contains('m')) {
        return double.tryParse(
          distanceText.replaceAll('m', '').trim()
        ) ?? 0.0;
      }
    } catch (e) {
      debugPrint('Error parsing distance: $e');
    }
    return 0.0;
  }

  Map<String, dynamic>? _getCurrentTransitStep() {
    if (_state.transitDetails.isEmpty) return null;

    if (_state.currentTransitStep == null) {
      return null;
    }

    if (_state.currentTransitStep is Map<String, dynamic>) {
      return _state.currentTransitStep as Map<String, dynamic>;
    }

    if (_state.currentTransitStep is int) {
      final int index = _state.currentTransitStep;
      if (index >= 0 && index < _state.transitDetails.length) {
        final detail = _state.transitDetails[index];
        if (detail is Map<String, dynamic>) {
          return detail;
        }
      }
    }

    return {'isOnboard': false};
  }

  @override
  void dispose() {
    if (!_mapController.isCompleted) {
      try {
        _mapController.future.then((controller) {
          controller.dispose();
        });
      } catch (e) {
        debugPrint('Error disposing map controller: $e');
      }
    }
    _stateManager.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }
}
