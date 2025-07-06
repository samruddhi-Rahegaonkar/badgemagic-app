import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/BadgeAliasProvider.dart';
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
  late List<TextEditingController> _aliasControllers;

  @override
  void initState() {
    super.initState();
    _setOrientation();

    final scanProvider = Provider.of<BadgeScanProvider>(context, listen: false);
    final aliasProvider =
        Provider.of<BadgeAliasProvider>(context, listen: false);

    _scanMode = scanProvider.mode;
    _controllers = [];
    _aliasControllers = [];

    for (final name in scanProvider.badgeNames) {
      _controllers.add(TextEditingController(text: name));
      _aliasControllers.add(
        TextEditingController(text: aliasProvider.getAlias(name) ?? ""),
      );
    }
  }

  void _setOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final c in _aliasControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      index: 4,
      title: 'Badge Magic',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text('Language',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDropdown(
              selectedValue: selectedLanguage,
              values: languages,
              onChanged: (value) => setState(() => selectedLanguage = value),
            ),
            const SizedBox(height: 24),
            const Text('Badge Scan Mode',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RadioListTile<BadgeScanMode>(
              title: const Text('Connect to any badge'),
              value: BadgeScanMode.any,
              groupValue: _scanMode,
              onChanged: (value) => setState(() => _scanMode = value!),
            ),
            RadioListTile<BadgeScanMode>(
              title: const Text('Connect to badges with the following names'),
              value: BadgeScanMode.specific,
              groupValue: _scanMode,
              onChanged: (value) => setState(() => _scanMode = value!),
            ),
            if (_scanMode == BadgeScanMode.specific)
              ...List.generate(_controllers.length, (index) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: TextField(
                              controller: _controllers[index],
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
                              _controllers.removeAt(index).dispose();
                              _aliasControllers.removeAt(index).dispose();
                            });
                          },
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextField(
                        controller: _aliasControllers[index],
                        decoration: const InputDecoration(
                          hintText: 'Alias (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            if (_scanMode == BadgeScanMode.specific)
              TextButton.icon(
                onPressed: () => setState(() {
                  _controllers.add(TextEditingController());
                  _aliasControllers.add(TextEditingController());
                }),
                icon: const Icon(Icons.add),
                label: const Text('Add More'),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final provider =
                    Provider.of<BadgeScanProvider>(context, listen: false);
                provider.setMode(_scanMode);
                final badgeNames = <String>[];
                final aliasMap = <String, String>{};

                for (int i = 0; i < _controllers.length; i++) {
                  final name = _controllers[i].text.trim();
                  final alias = _aliasControllers[i].text.trim();
                  if (name.isNotEmpty) {
                    badgeNames.add(name);
                    if (alias.isNotEmpty) {
                      aliasMap[name] = alias;
                    }
                  }
                }
                provider.setBadgeNames(badgeNames);
                final aliasProvider =
                    Provider.of<BadgeAliasProvider>(context, listen: false);
                aliasProvider.clearAll();
                aliasMap.forEach(
                    (name, alias) => aliasProvider.setAlias(name, alias));

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
          icon: Icon(Icons.arrow_drop_down, color: mdGrey400),
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
