import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'mana_pip.dart';

/// Structured filter panel that compiles its state to a query string.
///
/// The builder surfaces controls for color identity, card type, price range,
/// set, rarity, treatment, oracle text, and an "idle only" toggle. Each
/// section's state is compiled to the query grammar and emitted via
/// [onQueryChanged].
class QueryFilterBuilder extends StatefulWidget {
  const QueryFilterBuilder({
    super.key,
    required this.onQueryChanged,
    this.initialQuery,
  });

  final ValueChanged<String> onQueryChanged;
  final String? initialQuery;

  @override
  State<QueryFilterBuilder> createState() => QueryFilterBuilderState();
}

class QueryFilterBuilderState extends State<QueryFilterBuilder> {
  // -- Color (tri-state per color) --
  // 0 = unselected, 1 = selected, 2 = deselected
  late final List<int> _colorStates;

  // -- Color match mode: false = colors (c:), true = identity (id:) --
  // Identity matters for cards like Ghostfire (colorless, but red identity).
  late bool _useIdentity;

  // -- Card types --
  static const _cardTypes = [
    'Creature',
    'Instant',
    'Sorcery',
    'Artifact',
    'Enchantment',
    'Planeswalker',
    'Land',
    'Battle',
  ];
  late final Set<String> _selectedTypes;

  // -- Price range --
  late double _priceMin;
  late double _priceMax;
  static const _priceAbsMax = 100.0;

  // -- Set code --
  late final TextEditingController _setController;

  // -- Rarity --
  static const _rarities = ['Common', 'Uncommon', 'Rare', 'Mythic'];
  late final Set<String> _selectedRarities;

  // -- Treatments --
  static const _treatments = [
    'Foil',
    'Etched',
    'Full Art',
    'Showcase',
    'Borderless',
    'Promo',
  ];
  late final Set<String> _selectedTreatments;

  // -- Oracle text --
  late final TextEditingController _oracleController;

  // -- Name (free text) --
  late final TextEditingController _nameController;

  // -- Idle only --
  late bool _idleOnly;

  // -- In collection only --
  late bool _inCollectionOnly;

  @override
  void initState() {
    super.initState();
    _colorStates = List.filled(ManaPips.labels.length, 0);
    _useIdentity = false;
    _selectedTypes = {};
    _priceMin = 0;
    _priceMax = _priceAbsMax;
    _nameController = TextEditingController();
    _setController = TextEditingController();
    _selectedRarities = {};
    _selectedTreatments = {};
    _oracleController = TextEditingController();
    _idleOnly = false;
    _inCollectionOnly = false;

    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _parseInitialQuery(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setController.dispose();
    _oracleController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Parse initial query (best-effort)
  // ---------------------------------------------------------------------------

  void _parseInitialQuery(String q) {
    // Extract oracle text first (quoted, may contain spaces)
    final oracleMatch = RegExp(r'o:"([^"]*)"').firstMatch(q);
    if (oracleMatch != null) {
      _oracleController.text = oracleMatch.group(1)!;
    }

    // Extract type patterns (including parenthesized groups)
    final typeMatches = RegExp(r't:(\w+)').allMatches(q);
    for (final m in typeMatches) {
      final val = m.group(1)!;
      final match = _cardTypes.where(
        (t) => t.toLowerCase() == val.toLowerCase(),
      );
      if (match.isNotEmpty) _selectedTypes.add(match.first);
    }

    // Strip recognized structured tokens to find bare text
    var remaining = q
        .replaceAll(RegExp(r'o:"[^"]*"'), '')
        .replaceAll(RegExp(r'\([^)]*\)'), '') // grouped types
        .replaceAll(RegExp(r'-c:\S+'), '')
        .replaceAll(RegExp(r'c:\S+'), '')
        .replaceAll(RegExp(r'-id:\S+'), '')
        .replaceAll(RegExp(r'id:\S+'), '')
        .replaceAll(RegExp(r't:\S+'), '')
        .replaceAll(RegExp(r'usd[<>]=?\S+'), '')
        .replaceAll(RegExp(r's:\S+'), '')
        .replaceAll(RegExp(r'r:\S+'), '')
        .replaceAll(RegExp(r'is:\S+'), '')
        .replaceAll(RegExp(r'unused:\S+'), '')
        .replaceAll(RegExp(r'have:\S+'), '')
        .replaceAll(RegExp(r'\bOR\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (remaining.isNotEmpty) {
      _nameController.text = remaining;
    }

    final tokens = q.split(RegExp(r'\s+'));
    for (final token in tokens) {
      if (token.startsWith('c:') || token.startsWith('id:')) {
        if (token.startsWith('id:')) _useIdentity = true;
        final value = token.substring(token.indexOf(':') + 1);
        final letters = value.toUpperCase().split('');
        for (final l in letters) {
          final idx = ManaPips.labels.indexOf(l);
          if (idx >= 0) _colorStates[idx] = 1;
        }
      } else if (token.startsWith('-c:') || token.startsWith('-id:')) {
        if (token.startsWith('-id:')) _useIdentity = true;
        final l = token.substring(token.indexOf(':') + 1).toUpperCase();
        final idx = ManaPips.labels.indexOf(l);
        if (idx >= 0) _colorStates[idx] = 2;
      } else if (token.startsWith('s:')) {
        _setController.text = token.substring(2);
      } else if (token.startsWith('r:')) {
        final r = token.substring(2);
        final match = _rarities.where(
          (rr) => rr.toLowerCase() == r.toLowerCase(),
        );
        if (match.isNotEmpty) _selectedRarities.add(match.first);
      } else if (token.startsWith('is:')) {
        final flag = token.substring(3).toLowerCase();
        final match = _treatments.where(
          (t) => t.toLowerCase().replaceAll(' ', '') == flag,
        );
        if (match.isNotEmpty) _selectedTreatments.add(match.first);
      } else if (token.startsWith('usd>=')) {
        _priceMin = double.tryParse(token.substring(5)) ?? 0;
      } else if (token.startsWith('usd<=')) {
        _priceMax = double.tryParse(token.substring(5)) ?? _priceAbsMax;
      } else if (token == 'unused:true') {
        _idleOnly = true;
      } else if (token == 'have:true') {
        _inCollectionOnly = true;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Compile state to query string
  // ---------------------------------------------------------------------------

  String _compileQuery() {
    final parts = <String>[];

    // Name (free text)
    final name = _nameController.text.trim();
    if (name.isNotEmpty) parts.add(name);

    // Colors: selected letters joined into c:WUB (or id:WUB in identity mode)
    final colorField = _useIdentity ? 'id' : 'c';
    final selected = <String>[];
    final deselected = <String>[];
    for (var i = 0; i < _colorStates.length; i++) {
      if (_colorStates[i] == 1) selected.add(ManaPips.labels[i]);
      if (_colorStates[i] == 2) deselected.add(ManaPips.labels[i]);
    }
    if (selected.isNotEmpty) parts.add('$colorField:${selected.join()}');
    for (final d in deselected) {
      parts.add('-$colorField:$d');
    }

    // Types
    if (_selectedTypes.length == 1) {
      parts.add('t:${_selectedTypes.first.toLowerCase()}');
    } else if (_selectedTypes.length > 1) {
      final inner = _selectedTypes
          .map((t) => 't:${t.toLowerCase()}')
          .join(' OR ');
      parts.add('($inner)');
    }

    // Price range
    if (_priceMin > 0) {
      parts.add('usd>=${_priceMin.toStringAsFixed(0)}');
    }
    if (_priceMax < _priceAbsMax) {
      parts.add('usd<=${_priceMax.toStringAsFixed(0)}');
    }

    // Set
    final setCode = _setController.text.trim();
    if (setCode.isNotEmpty) parts.add('s:$setCode');

    // Rarity
    for (final r in _selectedRarities) {
      parts.add('r:${r.toLowerCase()}');
    }

    // Treatments
    for (final t in _selectedTreatments) {
      parts.add('is:${t.toLowerCase().replaceAll(' ', '')}');
    }

    // Oracle text
    final oracle = _oracleController.text.trim();
    if (oracle.isNotEmpty) parts.add('o:"$oracle"');

    // Idle only
    if (_idleOnly) parts.add('unused:true');

    // In collection only
    if (_inCollectionOnly) parts.add('have:true');

    return parts.join(' ');
  }

  void _emitQuery() {
    widget.onQueryChanged(_compileQuery());
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  ManaPipState _pipState(int stateValue) {
    switch (stateValue) {
      case 1:
        return ManaPipState.selected;
      case 2:
        return ManaPipState.deselected;
      default:
        return ManaPipState.unselected;
    }
  }

  void _cycleColor(int index) {
    setState(() {
      _colorStates[index] = (_colorStates[index] + 1) % 3;
    });
    _emitQuery();
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        text.toUpperCase(),
        style: AppTypography.sectionLabel,
      ),
    );
  }

  Widget _colorModeChip(String label, {required bool useIdentity}) {
    final isSelected = _useIdentity == useIdentity;
    return ChoiceChip(
      label: Text(label, style: AppTypography.bodySm.copyWith(
        color: isSelected ? AppColors.neutral0 : AppColors.neutral700,
      )),
      selected: isSelected,
      selectedColor: AppColors.neutral900,
      backgroundColor: AppColors.neutral50,
      side: BorderSide(
        color: isSelected ? AppColors.neutral900 : AppColors.neutral200,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      showCheckmark: false,
      onSelected: (_) {
        if (_useIdentity == useIdentity) return;
        setState(() => _useIdentity = useIdentity);
        _emitQuery();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Name --
          _sectionLabel('Name'),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'e.g. lightning bolt',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(color: AppColors.neutral200),
              ),
            ),
            style: AppTypography.query,
            onChanged: (_) => _emitQuery(),
          ),

          // -- Color --
          _sectionLabel('Color'),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(ManaPips.labels.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ManaPip(
                  color: ManaPips.labels[i],
                  size: ManaPipSize.filter,
                  state: _pipState(_colorStates[i]),
                  onTap: () => _cycleColor(i),
                ),
              );
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Colors match printed colors; identity matches deck-legality
          // identity (e.g. Ghostfire is colorless but has red identity).
          Row(
            children: [
              _colorModeChip('Colors', useIdentity: false),
              const SizedBox(width: AppSpacing.sm),
              _colorModeChip('Identity', useIdentity: true),
            ],
          ),

          // -- Card Type --
          _sectionLabel('Card Type'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _cardTypes.map((type) {
              final isSelected = _selectedTypes.contains(type);
              return FilterChip(
                label: Text(type, style: AppTypography.bodySm.copyWith(
                  color: isSelected ? AppColors.neutral0 : AppColors.neutral700,
                )),
                selected: isSelected,
                selectedColor: AppColors.neutral900,
                backgroundColor: AppColors.neutral50,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.neutral900
                      : AppColors.neutral200,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                checkmarkColor: AppColors.neutral0,
                showCheckmark: false,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTypes.add(type);
                    } else {
                      _selectedTypes.remove(type);
                    }
                  });
                  _emitQuery();
                },
              );
            }).toList(),
          ),

          // -- Price Range --
          _sectionLabel('Price Range (USD)'),
          Row(
            children: [
              SizedBox(
                width: 50,
                child: Text(
                  '\$${_priceMin.toStringAsFixed(0)}',
                  style: AppTypography.meta,
                ),
              ),
              Expanded(
                child: RangeSlider(
                  values: RangeValues(_priceMin, _priceMax),
                  min: 0,
                  max: _priceAbsMax,
                  divisions: 100,
                  activeColor: AppColors.neutral900,
                  inactiveColor: AppColors.neutral150,
                  onChanged: (values) {
                    setState(() {
                      _priceMin = values.start;
                      _priceMax = values.end;
                    });
                  },
                  onChangeEnd: (_) => _emitQuery(),
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  _priceMax >= _priceAbsMax
                      ? '\$100+'
                      : '\$${_priceMax.toStringAsFixed(0)}',
                  textAlign: TextAlign.right,
                  style: AppTypography.meta,
                ),
              ),
            ],
          ),

          // -- Set --
          _sectionLabel('Set'),
          TextField(
            controller: _setController,
            decoration: InputDecoration(
              hintText: 'e.g. mh2',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(color: AppColors.neutral200),
              ),
            ),
            style: AppTypography.query,
            onChanged: (_) => _emitQuery(),
          ),

          // -- Rarity --
          _sectionLabel('Rarity'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _rarities.map((rarity) {
              final isSelected = _selectedRarities.contains(rarity);
              return FilterChip(
                label: Text(rarity, style: AppTypography.bodySm.copyWith(
                  color: isSelected ? AppColors.neutral0 : AppColors.neutral700,
                )),
                selected: isSelected,
                selectedColor: AppColors.neutral900,
                backgroundColor: AppColors.neutral50,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.neutral900
                      : AppColors.neutral200,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                checkmarkColor: AppColors.neutral0,
                showCheckmark: false,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedRarities.add(rarity);
                    } else {
                      _selectedRarities.remove(rarity);
                    }
                  });
                  _emitQuery();
                },
              );
            }).toList(),
          ),

          // -- Treatment --
          _sectionLabel('Treatment'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _treatments.map((treatment) {
              final isSelected = _selectedTreatments.contains(treatment);
              return FilterChip(
                label: Text(treatment, style: AppTypography.bodySm.copyWith(
                  color: isSelected ? AppColors.neutral0 : AppColors.neutral700,
                )),
                selected: isSelected,
                selectedColor: AppColors.neutral900,
                backgroundColor: AppColors.neutral50,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.neutral900
                      : AppColors.neutral200,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                checkmarkColor: AppColors.neutral0,
                showCheckmark: false,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedTreatments.add(treatment);
                    } else {
                      _selectedTreatments.remove(treatment);
                    }
                  });
                  _emitQuery();
                },
              );
            }).toList(),
          ),

          // -- Oracle Text --
          _sectionLabel('Oracle Text'),
          TextField(
            controller: _oracleController,
            decoration: InputDecoration(
              hintText: 'e.g. draw a card',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.md),
                borderSide: const BorderSide(color: AppColors.neutral200),
              ),
            ),
            style: AppTypography.query,
            onChanged: (_) => _emitQuery(),
          ),

          // -- Status --
          _sectionLabel('Status'),
          Row(
            children: [
              Switch(
                value: _inCollectionOnly,
                activeThumbColor: AppColors.neutral900,
                onChanged: (value) {
                  setState(() {
                    _inCollectionOnly = value;
                  });
                  _emitQuery();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('In collection', style: AppTypography.bodySm),
            ],
          ),
          Row(
            children: [
              Switch(
                value: _idleOnly,
                activeThumbColor: AppColors.neutral900,
                onChanged: (value) {
                  setState(() {
                    _idleOnly = value;
                  });
                  _emitQuery();
                },
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Idle only', style: AppTypography.bodySm),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}
