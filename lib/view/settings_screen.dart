import 'package:badgemagic/constants.dart';
import 'package:badgemagic/providers/BadgeAliasProvider.dart';
import 'package:badgemagic/providers/BadgeScanProvider.dart';
import 'package:badgemagic/view/widgets/common_scaffold_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import 'package:badgemagic/services/localization_service.dart';
import 'package:badgemagic/main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  String selectedLanguage = 'en';
  final List<String> languages = ['en', 'hi'];

  late BadgeScanMode _scanMode;
  late List<TextEditingController> _controllers;
  late List<TextEditingController> _aliasControllers;
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
      for (final controller in _aliasControllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = GetIt.instance.get<LocalizationService>().l10n;
    return Consumer2<BadgeScanProvider, BadgeAliasProvider>(
      builder: (context, scanProvider, aliasProvider, child) {
        if (!scanProvider.isLoaded) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Initialize controllers once after provider is loaded
        if (!_initialized) {
          _scanMode = scanProvider.mode;
          _controllers = scanProvider.badgeNames
              .map((name) => TextEditingController(text: name))
              .toList();
          _aliasControllers = scanProvider.badgeNames
              .map((name) =>
                  TextEditingController(text: aliasProvider.getAlias(name) ?? ""))
              .toList();
          _initialized = true;
        }

        return CommonScaffold(
          index: 4,
          title: l10n.settings,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Text(l10n.language,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: Localizations.localeOf(context).languageCode,
                  items: [
                    DropdownMenuItem(
                      value: 'en',
                      child: Text(l10n.english),
                    ),
                    DropdownMenuItem(
                      value: 'hi',
                      child: Text(l10n.hindi),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedLanguage = value;
                      });
                      final newLocale = Locale(value);
                      appLocale.value = newLocale;
                      GetIt.instance
                          .get<LocalizationService>()
                          .saveLocale(newLocale);
                    }
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
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
                if (_scanMode == BadgeScanMode.specific) ...[
                  ..._controllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final nameController = entry.value;
                    final aliasController = _aliasControllers[index];

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                    hintText: 'Badge name',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    scanProvider.updateBadgeName(
                                        index, value.trim());
                                  },
                                ),
                              ),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                setState(() {
                                  nameController.dispose();
                                  aliasController.dispose();
                                  _controllers.removeAt(index);
                                  _aliasControllers.removeAt(index);
                                  scanProvider.removeBadgeNameAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: TextField(
                            controller: aliasController,
                            decoration: const InputDecoration(
                              hintText: 'Alias (optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _controllers.add(TextEditingController());
                      _aliasControllers.add(TextEditingController());
                      scanProvider.addBadgeName('');
                    }),
                    icon: const Icon(Icons.add),
                    label: const Text('Add More'),
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    scanProvider.setMode(_scanMode);
                    scanProvider.setBadgeNames(
                      _controllers.map((c) => c.text.trim()).toList(),
                    );
                    aliasProvider.clearAll();
                    for (int i = 0; i < _controllers.length; i++) {
                      final name = _controllers[i].text.trim();
                      final alias = _aliasControllers[i].text.trim();
                      if (name.isNotEmpty && alias.isNotEmpty) {
                        aliasProvider.setAlias(name, alias);
                      }
                    }
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
}


//   Widget _buildDropdown({
//     required String selectedValue,
//     required List<String> values,
//     required Function(String) onChanged,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           value: selectedValue,
//           isExpanded: true,
//           icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
//           onChanged: (String? newValue) {
//             if (newValue != null) onChanged(newValue);
//           },
//           items: values.map<DropdownMenuItem<String>>((String value) {
//             return DropdownMenuItem<String>(
//               value: value,
//               child: Text(value, style: const TextStyle(color: Colors.black)),
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
// }
}
