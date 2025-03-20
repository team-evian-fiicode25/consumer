import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../widgets/gradient_background.dart';
import '../../core/theme/app_theme.dart';

class TermsPoliciesPage extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onCancel;

  const TermsPoliciesPage({
    Key? key,
    required this.onAccept,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<TermsPoliciesPage> createState() => _TermsPoliciesPageState();
}

class _TermsPoliciesPageState extends State<TermsPoliciesPage> {
  bool _tosAccepted = false;
  bool _privacyPolicyAccepted = false;
  String _termsOfServiceText = '';
  String _privacyPolicyText = '';
  
  bool get _bothPoliciesAccepted => _tosAccepted && _privacyPolicyAccepted;

  @override
  void initState() {
    super.initState();
    _loadLegalDocuments();
  }

  Future<void> _loadLegalDocuments() async {
    try {
      final termsText = await rootBundle.loadString('assets/legal/terms_of_service.txt');
      final privacyText = await rootBundle.loadString('assets/legal/privacy_policy.txt');
      
      if (mounted) {
        setState(() {
          _termsOfServiceText = termsText;
          _privacyPolicyText = privacyText;
        });
      }
    } catch (e) {
      debugPrint('Error loading legal documents: $e');
    }
  }

  void _showPolicyDialog(String title) {
    final ScrollController scrollController = ScrollController();
    bool reachedEnd = false;
    
    void _onScrollUpdate(StateSetter setDialogState) {
      if (!reachedEnd && 
          scrollController.hasClients &&
          scrollController.offset >= scrollController.position.maxScrollExtent - 50) {
        setDialogState(() {
          reachedEnd = true;
        });
      }
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        final isLandscape = size.width > size.height;
        
        final dialog = AlertDialog(
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: isLandscape ? size.width * 0.85 : size.width * 0.85,
            height: isLandscape ? size.height * 0.85 : size.height * 0.6,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  scrollController.addListener(() {
                    _onScrollUpdate(setDialogState);
                  });
                });

                return Column(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Scrollbar(
                            controller: scrollController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Text(
                                title == 'Terms of Service' 
                                    ? _termsOfServiceText 
                                    : _privacyPolicyText,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                          if (!reachedEnd)
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Theme.of(context).cardTheme.color!.withOpacity(0),
                                      Theme.of(context).cardTheme.color!,
                                    ],
                                  ),
                                ),
                                child: Text(
                                  'Scroll to continue',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).extension<CustomStyles>()?.scrollTooltipStyle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: reachedEnd
                                ? () {
                                    setState(() {
                                      if (title == 'Terms of Service') {
                                        _tosAccepted = true;
                                      } else {
                                        _privacyPolicyAccepted = true;
                                      }
                                    });
                                    Navigator.of(context).pop();
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: reachedEnd 
                                  ? Theme.of(context).colorScheme.primary 
                                  : Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'I Accept',
                              style: TextStyle(
                                color: reachedEnd 
                                    ? Colors.white 
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );

        if (isLandscape) {
          return Dialog.fullscreen(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dialog.title!,
                  const SizedBox(height: 20),
                  Expanded(
                    child: dialog.content!,
                  ),
                ],
              ),
            ),
          );
        }

        return dialog;
      },
    ).then((_) => scrollController.dispose());
  }
  
  Widget _buildPolicyButton({
    required String title,
    required IconData icon,
    required bool accepted,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        backgroundColor: accepted 
            ? Colors.green.withOpacity(0.1) 
            : Theme.of(context).colorScheme.surface,
        side: BorderSide(
          color: accepted
              ? Colors.green
              : Theme.of(context).colorScheme.outline,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            accepted ? Icons.check_circle : icon,
            color: accepted ? Colors.green : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                  ),
                ),
                Text(
                  accepted ? 'Accepted' : 'Required',
                  style: TextStyle(
                    fontSize: 12,
                    color: accepted ? Colors.green : Colors.amber[800],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final verticalPadding = screenSize.height * 0.02;
    final horizontalPadding = screenSize.width * 0.04;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GradientBackground(height: isLandscape ? screenSize.height : screenSize.height * 0.3),
          
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: isSmallScreen ? 22 : 24,
                ),
                onPressed: widget.onCancel,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isLandscape ? 900 : 600,
                    minHeight: screenSize.height * 0.7,
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: isLandscape ? verticalPadding : screenSize.height * 0.04),
                      
                      Column(
                        children: [
                          Text(
                            'Terms & Policies',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 24 : 28,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please read and accept our policies',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      SizedBox(height: isLandscape ? verticalPadding : screenSize.height * 0.03),
                      
                      isLandscape
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildPolicyCard(context, isSmallScreen, horizontalPadding),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildPolicyButtonsCard(isSmallScreen, horizontalPadding),
                                      SizedBox(height: verticalPadding),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: _bothPoliciesAccepted ? widget.onAccept : null,
                                                  style: ElevatedButton.styleFrom(
                                                    padding: EdgeInsets.symmetric(
                                                      vertical: verticalPadding * 0.7,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Continue',
                                                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: horizontalPadding * 0.5),
                                              Expanded(
                                                child: OutlinedButton(
                                                  onPressed: widget.onCancel,
                                                  style: OutlinedButton.styleFrom(
                                                    padding: EdgeInsets.symmetric(
                                                      vertical: verticalPadding * 0.7,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Go Back',
                                                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildPolicyCard(context, isSmallScreen, horizontalPadding),
                                const SizedBox(height: 16),
                                _buildPolicyButtonsCard(isSmallScreen, horizontalPadding),
                                SizedBox(height: screenSize.height * 0.04),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: _bothPoliciesAccepted ? widget.onAccept : null,
                                            style: ElevatedButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                vertical: verticalPadding * 0.7,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              'Continue',
                                              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: horizontalPadding * 0.5),
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: widget.onCancel,
                                            style: OutlinedButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                vertical: verticalPadding * 0.7,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              'Go Back',
                                              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPolicyCard(BuildContext context, bool isSmallScreen, double horizontalPadding) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: isSmallScreen ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Terms and Privacy',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 16 : 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: horizontalPadding * 0.5),
            Text(
              'Please read and agree to our Terms of Service and Privacy Policy.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: isSmallScreen ? 13 : 14,
              ),
            ),
            SizedBox(height: horizontalPadding),
            
            Container(
              padding: EdgeInsets.all(horizontalPadding * 0.6),
              decoration: BoxDecoration(
                color: _bothPoliciesAccepted 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _bothPoliciesAccepted ? Colors.green : Colors.amber,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _bothPoliciesAccepted ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: _bothPoliciesAccepted ? Colors.green : Colors.amber,
                    size: isSmallScreen ? 18 : 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _bothPoliciesAccepted
                          ? 'All policies accepted'
                          : 'Both documents must be accepted',
                      style: TextStyle(
                        color: _bothPoliciesAccepted ? Colors.green : Colors.amber[900],
                        fontWeight: FontWeight.w500,
                        fontSize: isSmallScreen ? 12 : 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyButtonsCard(bool isSmallScreen, double horizontalPadding) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.policy_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: isSmallScreen ? 20 : 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Policy Documents',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 16 : 18,
                  ),
                ),
              ],
            ),
            SizedBox(height: horizontalPadding),
            _buildPolicyButton(
              title: 'Terms of Service',
              icon: Icons.description_outlined,
              accepted: _tosAccepted,
              onPressed: () => _showPolicyDialog('Terms of Service'),
            ),
            const SizedBox(height: 12),
            _buildPolicyButton(
              title: 'Privacy Policy',
              icon: Icons.privacy_tip_outlined,
              accepted: _privacyPolicyAccepted,
              onPressed: () => _showPolicyDialog('Privacy Policy'),
            ),
          ],
        ),
      ),
    );
  }
}