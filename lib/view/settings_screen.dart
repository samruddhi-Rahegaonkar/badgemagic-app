import 'package:badgemagic/providers/BadgeScanProvider.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  String selectedLanguage = 'ENGLISH';
  final List<String> languages = ['ENGLISH', 'CHINESE'];

  late BadgeScanMode _scanMode;
  late List<TextEditingController> _controllers;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _setOrientation();
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    if (_initialized) {
      for (final controller in _controllers) {
        controller.dispose();
      }
    }
    super.dispose();
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

        // Initialize controllers once after provider is loaded
        if (!_initialized) {
          _scanMode = provider.mode;
          _controllers = provider.badgeNames
              .map((name) => TextEditingController(text: name))
              .toList();
          _initialized = true;
        }

        return CommonScaffold(
          index: 4,
          title: 'Badge Magic',
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const Text('Language',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildDropdown(
                  selectedValue: selectedLanguage,
                  values: languages,
                  onChanged: (value) =>
                      setState(() => selectedLanguage = value),
                ),
                const SizedBox(height: 24),
                const Text('Badge Scan Mode',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                RadioListTile<BadgeScanMode>(
                  title: const Text('Connect to any badge'),
                  value: BadgeScanMode.any,
                  groupValue: _scanMode,
                  onChanged: (value) => setState(() => _scanMode = value!),
                ),
                RadioListTile<BadgeScanMode>(
                  title:
                      const Text('Connect to badges with the following names'),
                  value: BadgeScanMode.specific,
                  groupValue: _scanMode,
                  onChanged: (value) => setState(() => _scanMode = value!),
                ),
                if (_scanMode == BadgeScanMode.specific)
                  ..._controllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
                    return Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: 'Badge name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            setState(() {
                              controller.dispose();
                              _controllers.removeAt(index);
                            });
                          },
                        ),
                      ],
                    );
                  }).toList(),
                if (_scanMode == BadgeScanMode.specific)
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _controllers.add(TextEditingController());
                    }),
                    icon: const Icon(Icons.add),
                    label: const Text('Add More'),
                  ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    provider.setMode(_scanMode);
                    provider.setBadgeNames(
                      _controllers.map((c) => c.text.trim()).toList(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Scan settings saved')),
                    );
                  },
                  icon: const Icon(Icons.save),
                  label: const Text("Save Settings"),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String selectedValue,
    required List<String> values,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          onChanged: (String? newValue) {
            if (newValue != null) onChanged(newValue);
          },
          items: values.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: const TextStyle(color: Colors.black)),
            );
          }).toList(),
        ),
      ),
    );
  }
}
