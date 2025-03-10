import 'package:flutter/material.dart';

class TermsAndConditionsDialog extends StatefulWidget {
  const TermsAndConditionsDialog({super.key});

  @override
  State<TermsAndConditionsDialog> createState() => _TermsAndConditionsDialogState();
}

class _TermsAndConditionsDialogState extends State<TermsAndConditionsDialog> {
  final ScrollController _scrollController = ScrollController();
  bool _hasReachedBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent &&
        !_scrollController.position.outOfRange) {
      setState(() {
        _hasReachedBottom = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Terms and Conditions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Acceptance of Terms',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '2. User Account',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '3. Privacy Policy',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '4. User Conduct',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '5. Content',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '6. Intellectual Property',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '7. Termination',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                      ),
                      SizedBox(height: 16),
                      Text(
                        '8. Changes to Terms',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            if (!_hasReachedBottom)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.keyboard_double_arrow_down,
                      size: 16,
                      color: Colors.grey,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Scroll to continue',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _hasReachedBottom
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    child: const Text('Accept'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}