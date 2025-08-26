import 'package:badgemagic/providers/BadgeScanProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BadgeScanSettingsWidget extends StatefulWidget {
  final Function(BadgeScanMode mode, List<String> names)? onSave;

  const BadgeScanSettingsWidget({super.key, this.onSave});

  @override
  State<BadgeScanSettingsWidget> createState() =>
      _BadgeScanSettingsWidgetState();
}

class _BadgeScanSettingsWidgetState extends State<BadgeScanSettingsWidget> {
  late BadgeScanMode _mode;
  final List<TextEditingController> _controllers = [];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<BadgeScanProvider>(context, listen: false);
    _mode = provider.mode;
  }

  void _addBadgeName() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _removeBadgeName(int index) {
    setState(() {
      _controllers.removeAt(index).dispose();
    });
  }

  Future<void> _onSave() async {
    final updatedNames = _controllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    final provider = Provider.of<BadgeScanProvider>(context, listen: false);
    provider.setMode(_mode);
    provider.setBadgeNames(updatedNames);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scan settings saved successfully')),
    );

    widget.onSave?.call(_mode, updatedNames);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BadgeScanProvider>(
      builder: (context, provider, child) {
        if (!provider.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_controllers.isEmpty) {
          // Initialize controllers only after provider is loaded
          for (var name in provider.badgeNames) {
            _controllers.add(TextEditingController(text: name));
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Badge Scan Settings'),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _onSave,
              ),
            ],
          ),
          body: Column(
            children: [
              RadioListTile<BadgeScanMode>(
                title: const Text('Connect to any badge'),
                value: BadgeScanMode.any,
                groupValue: _mode,
                onChanged: (val) => setState(() => _mode = val!),
              ),
              RadioListTile<BadgeScanMode>(
                title: const Text('Connect to badges with the following names'),
                value: BadgeScanMode.specific,
                groupValue: _mode,
                onChanged: (val) => setState(() => _mode = val!),
              ),
              if (_mode == BadgeScanMode.specific)
                Expanded(
                  child: ListView.builder(
                    itemCount: _controllers.length,
                    itemBuilder: (context, index) {
                      return Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: TextField(
                                controller: _controllers[index],
                                decoration: const InputDecoration(
                                  labelText: 'Badge Name',
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _removeBadgeName(index),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              if (_mode == BadgeScanMode.specific)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton.icon(
                    onPressed: _addBadgeName,
                    icon: const Icon(Icons.add),
                    label: const Text("Add more"),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    super.dispose();
  }
}
