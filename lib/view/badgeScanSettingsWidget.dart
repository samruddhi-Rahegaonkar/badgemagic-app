import 'package:badgemagic/providers/BadgeAliasProvider.dart';
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
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _aliasControllers = [];

  @override
  void initState() {
    super.initState();
    final scanProvider = Provider.of<BadgeScanProvider>(context, listen: false);
    final aliasProvider =
        Provider.of<BadgeAliasProvider>(context, listen: false);

    _mode = scanProvider.mode;
    for (var name in scanProvider.badgeNames) {
      _nameControllers.add(TextEditingController(text: name));
      final alias = aliasProvider.getAlias(name) ?? "";
      _aliasControllers.add(TextEditingController(text: alias));
    }
  }

  void _addBadgeName() {
    setState(() {
      _nameControllers.add(TextEditingController());
      _aliasControllers.add(TextEditingController());
    });
    final scanProvider = Provider.of<BadgeScanProvider>(context, listen: false);
    scanProvider.addBadgeName('');
  }

  void _removeBadgeName(int index) {
    if (index < 0 || index >= _nameControllers.length) return;
    setState(() {
      _nameControllers.removeAt(index).dispose();
      _aliasControllers.removeAt(index).dispose();
    });
    final scanProvider = Provider.of<BadgeScanProvider>(context, listen: false);
    scanProvider.removeBadgeNameAt(index);
  }

  Future<void> _onSave() async {
    final updatedNames = <String>[];
    final Map<String, String> aliases = {};
    final Set<String> realNameSet = {};
    final Set<String> aliasSet = {};

    for (int i = 0; i < _nameControllers.length; i++) {
      final name = _nameControllers[i].text.trim();
      final alias = _aliasControllers[i].text.trim();

      if (name.isNotEmpty) {
        if (realNameSet.contains(name.toLowerCase())) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Duplicate real badge name: "$name"')),
          );
          return;
        }
        realNameSet.add(name.toLowerCase());
        updatedNames.add(name);

        if (alias.isNotEmpty) {
          if (aliasSet.contains(alias.toLowerCase())) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Duplicate alias: "$alias"')),
            );
            return;
          }
          aliasSet.add(alias.toLowerCase());
          aliases[name] = alias;
        }
      }
    }

    final scanProvider = Provider.of<BadgeScanProvider>(context, listen: false);
    scanProvider.setMode(_mode);
    scanProvider.setBadgeNames(updatedNames);

    final aliasProvider =
        Provider.of<BadgeAliasProvider>(context, listen: false);
    aliasProvider.clearAll();
    aliases.forEach((name, alias) => aliasProvider.setAlias(name, alias));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scan settings saved successfully')),
    );

    widget.onSave?.call(_mode, updatedNames);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    for (var controller in _aliasControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                itemCount: _nameControllers.length,
                itemBuilder: (context, index) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 4),
                              child: TextField(
                                controller: _nameControllers[index],
                                decoration: const InputDecoration(
                                  labelText: 'Real Badge Name',
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _removeBadgeName(index),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: TextField(
                          controller: _aliasControllers[index],
                          decoration: const InputDecoration(
                            labelText: 'Alias (Optional)',
                          ),
                        ),
                      ),
                      const Divider(),
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
  }
}
