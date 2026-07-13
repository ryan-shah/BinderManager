// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_database.dart';

// ignore_for_file: type=lint
class $StacksTable extends Stacks with TableInfo<$StacksTable, StackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StacksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scryfallIdMeta = const VerificationMeta(
    'scryfallId',
  );
  @override
  late final GeneratedColumn<String> scryfallId = GeneratedColumn<String>(
    'scryfall_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Finish, String> finish =
      GeneratedColumn<String>(
        'finish',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<Finish>($StacksTable.$converterfinish);
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conditionMeta = const VerificationMeta(
    'condition',
  );
  @override
  late final GeneratedColumn<String> condition = GeneratedColumn<String>(
    'condition',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _provenanceMeta = const VerificationMeta(
    'provenance',
  );
  @override
  late final GeneratedColumn<String> provenance = GeneratedColumn<String>(
    'provenance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scryfallId,
    finish,
    quantity,
    condition,
    language,
    provenance,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stacks';
  @override
  VerificationContext validateIntegrity(
    Insertable<StackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('scryfall_id')) {
      context.handle(
        _scryfallIdMeta,
        scryfallId.isAcceptableOrUnknown(data['scryfall_id']!, _scryfallIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scryfallIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('condition')) {
      context.handle(
        _conditionMeta,
        condition.isAcceptableOrUnknown(data['condition']!, _conditionMeta),
      );
    }
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    }
    if (data.containsKey('provenance')) {
      context.handle(
        _provenanceMeta,
        provenance.isAcceptableOrUnknown(data['provenance']!, _provenanceMeta),
      );
    } else if (isInserting) {
      context.missing(_provenanceMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {scryfallId, finish, provenance},
  ];
  @override
  StackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StackRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scryfallId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scryfall_id'],
      )!,
      finish: $StacksTable.$converterfinish.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}finish'],
        )!,
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      condition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}condition'],
      ),
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      ),
      provenance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $StacksTable createAlias(String alias) {
    return $StacksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Finish, String, String> $converterfinish =
      const EnumNameConverter<Finish>(Finish.values);
}

class StackRow extends DataClass implements Insertable<StackRow> {
  /// Client-generated UUID v4 — stable across devices for later sync (D12).
  final String id;
  final String scryfallId;
  final Finish finish;
  final int quantity;

  /// ManaBox condition string (e.g. `near_mint`), if known.
  final String? condition;

  /// Two-letter language code (e.g. `en`), if known.
  final String? language;

  /// Import source that owns this stack, e.g. `manabox`, `deck-import`.
  final String provenance;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StackRow({
    required this.id,
    required this.scryfallId,
    required this.finish,
    required this.quantity,
    this.condition,
    this.language,
    required this.provenance,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['scryfall_id'] = Variable<String>(scryfallId);
    {
      map['finish'] = Variable<String>(
        $StacksTable.$converterfinish.toSql(finish),
      );
    }
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || condition != null) {
      map['condition'] = Variable<String>(condition);
    }
    if (!nullToAbsent || language != null) {
      map['language'] = Variable<String>(language);
    }
    map['provenance'] = Variable<String>(provenance);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StacksCompanion toCompanion(bool nullToAbsent) {
    return StacksCompanion(
      id: Value(id),
      scryfallId: Value(scryfallId),
      finish: Value(finish),
      quantity: Value(quantity),
      condition: condition == null && nullToAbsent
          ? const Value.absent()
          : Value(condition),
      language: language == null && nullToAbsent
          ? const Value.absent()
          : Value(language),
      provenance: Value(provenance),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StackRow(
      id: serializer.fromJson<String>(json['id']),
      scryfallId: serializer.fromJson<String>(json['scryfallId']),
      finish: $StacksTable.$converterfinish.fromJson(
        serializer.fromJson<String>(json['finish']),
      ),
      quantity: serializer.fromJson<int>(json['quantity']),
      condition: serializer.fromJson<String?>(json['condition']),
      language: serializer.fromJson<String?>(json['language']),
      provenance: serializer.fromJson<String>(json['provenance']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scryfallId': serializer.toJson<String>(scryfallId),
      'finish': serializer.toJson<String>(
        $StacksTable.$converterfinish.toJson(finish),
      ),
      'quantity': serializer.toJson<int>(quantity),
      'condition': serializer.toJson<String?>(condition),
      'language': serializer.toJson<String?>(language),
      'provenance': serializer.toJson<String>(provenance),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StackRow copyWith({
    String? id,
    String? scryfallId,
    Finish? finish,
    int? quantity,
    Value<String?> condition = const Value.absent(),
    Value<String?> language = const Value.absent(),
    String? provenance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => StackRow(
    id: id ?? this.id,
    scryfallId: scryfallId ?? this.scryfallId,
    finish: finish ?? this.finish,
    quantity: quantity ?? this.quantity,
    condition: condition.present ? condition.value : this.condition,
    language: language.present ? language.value : this.language,
    provenance: provenance ?? this.provenance,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  StackRow copyWithCompanion(StacksCompanion data) {
    return StackRow(
      id: data.id.present ? data.id.value : this.id,
      scryfallId: data.scryfallId.present
          ? data.scryfallId.value
          : this.scryfallId,
      finish: data.finish.present ? data.finish.value : this.finish,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      condition: data.condition.present ? data.condition.value : this.condition,
      language: data.language.present ? data.language.value : this.language,
      provenance: data.provenance.present
          ? data.provenance.value
          : this.provenance,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StackRow(')
          ..write('id: $id, ')
          ..write('scryfallId: $scryfallId, ')
          ..write('finish: $finish, ')
          ..write('quantity: $quantity, ')
          ..write('condition: $condition, ')
          ..write('language: $language, ')
          ..write('provenance: $provenance, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scryfallId,
    finish,
    quantity,
    condition,
    language,
    provenance,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StackRow &&
          other.id == this.id &&
          other.scryfallId == this.scryfallId &&
          other.finish == this.finish &&
          other.quantity == this.quantity &&
          other.condition == this.condition &&
          other.language == this.language &&
          other.provenance == this.provenance &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StacksCompanion extends UpdateCompanion<StackRow> {
  final Value<String> id;
  final Value<String> scryfallId;
  final Value<Finish> finish;
  final Value<int> quantity;
  final Value<String?> condition;
  final Value<String?> language;
  final Value<String> provenance;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StacksCompanion({
    this.id = const Value.absent(),
    this.scryfallId = const Value.absent(),
    this.finish = const Value.absent(),
    this.quantity = const Value.absent(),
    this.condition = const Value.absent(),
    this.language = const Value.absent(),
    this.provenance = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StacksCompanion.insert({
    required String id,
    required String scryfallId,
    required Finish finish,
    required int quantity,
    this.condition = const Value.absent(),
    this.language = const Value.absent(),
    required String provenance,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scryfallId = Value(scryfallId),
       finish = Value(finish),
       quantity = Value(quantity),
       provenance = Value(provenance),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<StackRow> custom({
    Expression<String>? id,
    Expression<String>? scryfallId,
    Expression<String>? finish,
    Expression<int>? quantity,
    Expression<String>? condition,
    Expression<String>? language,
    Expression<String>? provenance,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scryfallId != null) 'scryfall_id': scryfallId,
      if (finish != null) 'finish': finish,
      if (quantity != null) 'quantity': quantity,
      if (condition != null) 'condition': condition,
      if (language != null) 'language': language,
      if (provenance != null) 'provenance': provenance,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StacksCompanion copyWith({
    Value<String>? id,
    Value<String>? scryfallId,
    Value<Finish>? finish,
    Value<int>? quantity,
    Value<String?>? condition,
    Value<String?>? language,
    Value<String>? provenance,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return StacksCompanion(
      id: id ?? this.id,
      scryfallId: scryfallId ?? this.scryfallId,
      finish: finish ?? this.finish,
      quantity: quantity ?? this.quantity,
      condition: condition ?? this.condition,
      language: language ?? this.language,
      provenance: provenance ?? this.provenance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scryfallId.present) {
      map['scryfall_id'] = Variable<String>(scryfallId.value);
    }
    if (finish.present) {
      map['finish'] = Variable<String>(
        $StacksTable.$converterfinish.toSql(finish.value),
      );
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (condition.present) {
      map['condition'] = Variable<String>(condition.value);
    }
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (provenance.present) {
      map['provenance'] = Variable<String>(provenance.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StacksCompanion(')
          ..write('id: $id, ')
          ..write('scryfallId: $scryfallId, ')
          ..write('finish: $finish, ')
          ..write('quantity: $quantity, ')
          ..write('condition: $condition, ')
          ..write('language: $language, ')
          ..write('provenance: $provenance, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DecksTable extends Decks with TableInfo<$DecksTable, Deck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DecksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAssembledMeta = const VerificationMeta(
    'isAssembled',
  );
  @override
  late final GeneratedColumn<bool> isAssembled = GeneratedColumn<bool>(
    'is_assembled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_assembled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isSharedMeta = const VerificationMeta(
    'isShared',
  );
  @override
  late final GeneratedColumn<bool> isShared = GeneratedColumn<bool>(
    'is_shared',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_shared" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    format,
    isAssembled,
    isShared,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'decks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Deck> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    }
    if (data.containsKey('is_assembled')) {
      context.handle(
        _isAssembledMeta,
        isAssembled.isAcceptableOrUnknown(
          data['is_assembled']!,
          _isAssembledMeta,
        ),
      );
    }
    if (data.containsKey('is_shared')) {
      context.handle(
        _isSharedMeta,
        isShared.isAcceptableOrUnknown(data['is_shared']!, _isSharedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Deck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Deck(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      ),
      isAssembled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_assembled'],
      )!,
      isShared: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_shared'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DecksTable createAlias(String alias) {
    return $DecksTable(attachedDatabase, alias);
  }
}

class Deck extends DataClass implements Insertable<Deck> {
  /// Client-generated UUID v4 — stable across devices for later sync (D12).
  final String id;
  final String name;

  /// Free-text format label (e.g. `commander`, `modern`), if given.
  final String? format;
  final bool isAssembled;
  final bool isShared;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Deck({
    required this.id,
    required this.name,
    this.format,
    required this.isAssembled,
    required this.isShared,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || format != null) {
      map['format'] = Variable<String>(format);
    }
    map['is_assembled'] = Variable<bool>(isAssembled);
    map['is_shared'] = Variable<bool>(isShared);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DecksCompanion toCompanion(bool nullToAbsent) {
    return DecksCompanion(
      id: Value(id),
      name: Value(name),
      format: format == null && nullToAbsent
          ? const Value.absent()
          : Value(format),
      isAssembled: Value(isAssembled),
      isShared: Value(isShared),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Deck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Deck(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      format: serializer.fromJson<String?>(json['format']),
      isAssembled: serializer.fromJson<bool>(json['isAssembled']),
      isShared: serializer.fromJson<bool>(json['isShared']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'format': serializer.toJson<String?>(format),
      'isAssembled': serializer.toJson<bool>(isAssembled),
      'isShared': serializer.toJson<bool>(isShared),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Deck copyWith({
    String? id,
    String? name,
    Value<String?> format = const Value.absent(),
    bool? isAssembled,
    bool? isShared,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Deck(
    id: id ?? this.id,
    name: name ?? this.name,
    format: format.present ? format.value : this.format,
    isAssembled: isAssembled ?? this.isAssembled,
    isShared: isShared ?? this.isShared,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Deck copyWithCompanion(DecksCompanion data) {
    return Deck(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      format: data.format.present ? data.format.value : this.format,
      isAssembled: data.isAssembled.present
          ? data.isAssembled.value
          : this.isAssembled,
      isShared: data.isShared.present ? data.isShared.value : this.isShared,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Deck(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('format: $format, ')
          ..write('isAssembled: $isAssembled, ')
          ..write('isShared: $isShared, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    format,
    isAssembled,
    isShared,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Deck &&
          other.id == this.id &&
          other.name == this.name &&
          other.format == this.format &&
          other.isAssembled == this.isAssembled &&
          other.isShared == this.isShared &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DecksCompanion extends UpdateCompanion<Deck> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> format;
  final Value<bool> isAssembled;
  final Value<bool> isShared;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DecksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.format = const Value.absent(),
    this.isAssembled = const Value.absent(),
    this.isShared = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DecksCompanion.insert({
    required String id,
    required String name,
    this.format = const Value.absent(),
    this.isAssembled = const Value.absent(),
    this.isShared = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Deck> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? format,
    Expression<bool>? isAssembled,
    Expression<bool>? isShared,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (format != null) 'format': format,
      if (isAssembled != null) 'is_assembled': isAssembled,
      if (isShared != null) 'is_shared': isShared,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DecksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? format,
    Value<bool>? isAssembled,
    Value<bool>? isShared,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DecksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      format: format ?? this.format,
      isAssembled: isAssembled ?? this.isAssembled,
      isShared: isShared ?? this.isShared,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (isAssembled.present) {
      map['is_assembled'] = Variable<bool>(isAssembled.value);
    }
    if (isShared.present) {
      map['is_shared'] = Variable<bool>(isShared.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DecksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('format: $format, ')
          ..write('isAssembled: $isAssembled, ')
          ..write('isShared: $isShared, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeckEntriesTable extends DeckEntries
    with TableInfo<$DeckEntriesTable, DeckEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeckEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scryfallIdMeta = const VerificationMeta(
    'scryfallId',
  );
  @override
  late final GeneratedColumn<String> scryfallId = GeneratedColumn<String>(
    'scryfall_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Finish?, String> finish =
      GeneratedColumn<String>(
        'finish',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<Finish?>($DeckEntriesTable.$converterfinishn);
  static const VerificationMeta _cardNameMeta = const VerificationMeta(
    'cardName',
  );
  @override
  late final GeneratedColumn<String> cardName = GeneratedColumn<String>(
    'card_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DeckSection, String> section =
      GeneratedColumn<String>(
        'section',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<DeckSection>($DeckEntriesTable.$convertersection);
  static const VerificationMeta _isSharedMeta = const VerificationMeta(
    'isShared',
  );
  @override
  late final GeneratedColumn<bool> isShared = GeneratedColumn<bool>(
    'is_shared',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_shared" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isUnownedMeta = const VerificationMeta(
    'isUnowned',
  );
  @override
  late final GeneratedColumn<bool> isUnowned = GeneratedColumn<bool>(
    'is_unowned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_unowned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _printingSpecifiedMeta = const VerificationMeta(
    'printingSpecified',
  );
  @override
  late final GeneratedColumn<bool> printingSpecified = GeneratedColumn<bool>(
    'printing_specified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("printing_specified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deckId,
    scryfallId,
    finish,
    cardName,
    quantity,
    section,
    isShared,
    isUnowned,
    printingSpecified,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deck_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeckEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('scryfall_id')) {
      context.handle(
        _scryfallIdMeta,
        scryfallId.isAcceptableOrUnknown(data['scryfall_id']!, _scryfallIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scryfallIdMeta);
    }
    if (data.containsKey('card_name')) {
      context.handle(
        _cardNameMeta,
        cardName.isAcceptableOrUnknown(data['card_name']!, _cardNameMeta),
      );
    } else if (isInserting) {
      context.missing(_cardNameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('is_shared')) {
      context.handle(
        _isSharedMeta,
        isShared.isAcceptableOrUnknown(data['is_shared']!, _isSharedMeta),
      );
    }
    if (data.containsKey('is_unowned')) {
      context.handle(
        _isUnownedMeta,
        isUnowned.isAcceptableOrUnknown(data['is_unowned']!, _isUnownedMeta),
      );
    }
    if (data.containsKey('printing_specified')) {
      context.handle(
        _printingSpecifiedMeta,
        printingSpecified.isAcceptableOrUnknown(
          data['printing_specified']!,
          _printingSpecifiedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeckEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeckEntryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      scryfallId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scryfall_id'],
      )!,
      finish: $DeckEntriesTable.$converterfinishn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}finish'],
        ),
      ),
      cardName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      section: $DeckEntriesTable.$convertersection.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}section'],
        )!,
      ),
      isShared: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_shared'],
      )!,
      isUnowned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_unowned'],
      )!,
      printingSpecified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}printing_specified'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DeckEntriesTable createAlias(String alias) {
    return $DeckEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Finish, String, String> $converterfinish =
      const EnumNameConverter<Finish>(Finish.values);
  static JsonTypeConverter2<Finish?, String?, String?> $converterfinishn =
      JsonTypeConverter2.asNullable($converterfinish);
  static JsonTypeConverter2<DeckSection, String, String> $convertersection =
      const EnumNameConverter<DeckSection>(DeckSection.values);
}

class DeckEntryRow extends DataClass implements Insertable<DeckEntryRow> {
  /// Client-generated UUID v4 (D12).
  final String id;
  final String deckId;

  /// Resolved printing. Always set by commit time; which printing depends
  /// on the list's `(SET) collector#` suffix or the fidelity choice (D3).
  final String scryfallId;

  /// v1 decklists never carry finish; reserved for Phase 4 allocation.
  final Finish? finish;

  /// The card name as written in the imported list (survives corpus
  /// refreshes and makes re-import diffs readable).
  final String cardName;
  final int quantity;
  final DeckSection section;

  /// Per-card shared override; effective sharing is
  /// `deck.isShared || entry.isShared` (D3).
  final bool isShared;

  /// Named in the list but not owned at import time (D10 option 2).
  final bool isUnowned;

  /// Whether the imported line carried a `(SET) collector#` suffix.
  final bool printingSpecified;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DeckEntryRow({
    required this.id,
    required this.deckId,
    required this.scryfallId,
    this.finish,
    required this.cardName,
    required this.quantity,
    required this.section,
    required this.isShared,
    required this.isUnowned,
    required this.printingSpecified,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['deck_id'] = Variable<String>(deckId);
    map['scryfall_id'] = Variable<String>(scryfallId);
    if (!nullToAbsent || finish != null) {
      map['finish'] = Variable<String>(
        $DeckEntriesTable.$converterfinishn.toSql(finish),
      );
    }
    map['card_name'] = Variable<String>(cardName);
    map['quantity'] = Variable<int>(quantity);
    {
      map['section'] = Variable<String>(
        $DeckEntriesTable.$convertersection.toSql(section),
      );
    }
    map['is_shared'] = Variable<bool>(isShared);
    map['is_unowned'] = Variable<bool>(isUnowned);
    map['printing_specified'] = Variable<bool>(printingSpecified);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DeckEntriesCompanion toCompanion(bool nullToAbsent) {
    return DeckEntriesCompanion(
      id: Value(id),
      deckId: Value(deckId),
      scryfallId: Value(scryfallId),
      finish: finish == null && nullToAbsent
          ? const Value.absent()
          : Value(finish),
      cardName: Value(cardName),
      quantity: Value(quantity),
      section: Value(section),
      isShared: Value(isShared),
      isUnowned: Value(isUnowned),
      printingSpecified: Value(printingSpecified),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DeckEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeckEntryRow(
      id: serializer.fromJson<String>(json['id']),
      deckId: serializer.fromJson<String>(json['deckId']),
      scryfallId: serializer.fromJson<String>(json['scryfallId']),
      finish: $DeckEntriesTable.$converterfinishn.fromJson(
        serializer.fromJson<String?>(json['finish']),
      ),
      cardName: serializer.fromJson<String>(json['cardName']),
      quantity: serializer.fromJson<int>(json['quantity']),
      section: $DeckEntriesTable.$convertersection.fromJson(
        serializer.fromJson<String>(json['section']),
      ),
      isShared: serializer.fromJson<bool>(json['isShared']),
      isUnowned: serializer.fromJson<bool>(json['isUnowned']),
      printingSpecified: serializer.fromJson<bool>(json['printingSpecified']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deckId': serializer.toJson<String>(deckId),
      'scryfallId': serializer.toJson<String>(scryfallId),
      'finish': serializer.toJson<String?>(
        $DeckEntriesTable.$converterfinishn.toJson(finish),
      ),
      'cardName': serializer.toJson<String>(cardName),
      'quantity': serializer.toJson<int>(quantity),
      'section': serializer.toJson<String>(
        $DeckEntriesTable.$convertersection.toJson(section),
      ),
      'isShared': serializer.toJson<bool>(isShared),
      'isUnowned': serializer.toJson<bool>(isUnowned),
      'printingSpecified': serializer.toJson<bool>(printingSpecified),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DeckEntryRow copyWith({
    String? id,
    String? deckId,
    String? scryfallId,
    Value<Finish?> finish = const Value.absent(),
    String? cardName,
    int? quantity,
    DeckSection? section,
    bool? isShared,
    bool? isUnowned,
    bool? printingSpecified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DeckEntryRow(
    id: id ?? this.id,
    deckId: deckId ?? this.deckId,
    scryfallId: scryfallId ?? this.scryfallId,
    finish: finish.present ? finish.value : this.finish,
    cardName: cardName ?? this.cardName,
    quantity: quantity ?? this.quantity,
    section: section ?? this.section,
    isShared: isShared ?? this.isShared,
    isUnowned: isUnowned ?? this.isUnowned,
    printingSpecified: printingSpecified ?? this.printingSpecified,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DeckEntryRow copyWithCompanion(DeckEntriesCompanion data) {
    return DeckEntryRow(
      id: data.id.present ? data.id.value : this.id,
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      scryfallId: data.scryfallId.present
          ? data.scryfallId.value
          : this.scryfallId,
      finish: data.finish.present ? data.finish.value : this.finish,
      cardName: data.cardName.present ? data.cardName.value : this.cardName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      section: data.section.present ? data.section.value : this.section,
      isShared: data.isShared.present ? data.isShared.value : this.isShared,
      isUnowned: data.isUnowned.present ? data.isUnowned.value : this.isUnowned,
      printingSpecified: data.printingSpecified.present
          ? data.printingSpecified.value
          : this.printingSpecified,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeckEntryRow(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('scryfallId: $scryfallId, ')
          ..write('finish: $finish, ')
          ..write('cardName: $cardName, ')
          ..write('quantity: $quantity, ')
          ..write('section: $section, ')
          ..write('isShared: $isShared, ')
          ..write('isUnowned: $isUnowned, ')
          ..write('printingSpecified: $printingSpecified, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deckId,
    scryfallId,
    finish,
    cardName,
    quantity,
    section,
    isShared,
    isUnowned,
    printingSpecified,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeckEntryRow &&
          other.id == this.id &&
          other.deckId == this.deckId &&
          other.scryfallId == this.scryfallId &&
          other.finish == this.finish &&
          other.cardName == this.cardName &&
          other.quantity == this.quantity &&
          other.section == this.section &&
          other.isShared == this.isShared &&
          other.isUnowned == this.isUnowned &&
          other.printingSpecified == this.printingSpecified &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DeckEntriesCompanion extends UpdateCompanion<DeckEntryRow> {
  final Value<String> id;
  final Value<String> deckId;
  final Value<String> scryfallId;
  final Value<Finish?> finish;
  final Value<String> cardName;
  final Value<int> quantity;
  final Value<DeckSection> section;
  final Value<bool> isShared;
  final Value<bool> isUnowned;
  final Value<bool> printingSpecified;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DeckEntriesCompanion({
    this.id = const Value.absent(),
    this.deckId = const Value.absent(),
    this.scryfallId = const Value.absent(),
    this.finish = const Value.absent(),
    this.cardName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.section = const Value.absent(),
    this.isShared = const Value.absent(),
    this.isUnowned = const Value.absent(),
    this.printingSpecified = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeckEntriesCompanion.insert({
    required String id,
    required String deckId,
    required String scryfallId,
    this.finish = const Value.absent(),
    required String cardName,
    required int quantity,
    required DeckSection section,
    this.isShared = const Value.absent(),
    this.isUnowned = const Value.absent(),
    this.printingSpecified = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deckId = Value(deckId),
       scryfallId = Value(scryfallId),
       cardName = Value(cardName),
       quantity = Value(quantity),
       section = Value(section),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DeckEntryRow> custom({
    Expression<String>? id,
    Expression<String>? deckId,
    Expression<String>? scryfallId,
    Expression<String>? finish,
    Expression<String>? cardName,
    Expression<int>? quantity,
    Expression<String>? section,
    Expression<bool>? isShared,
    Expression<bool>? isUnowned,
    Expression<bool>? printingSpecified,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deckId != null) 'deck_id': deckId,
      if (scryfallId != null) 'scryfall_id': scryfallId,
      if (finish != null) 'finish': finish,
      if (cardName != null) 'card_name': cardName,
      if (quantity != null) 'quantity': quantity,
      if (section != null) 'section': section,
      if (isShared != null) 'is_shared': isShared,
      if (isUnowned != null) 'is_unowned': isUnowned,
      if (printingSpecified != null) 'printing_specified': printingSpecified,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeckEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? deckId,
    Value<String>? scryfallId,
    Value<Finish?>? finish,
    Value<String>? cardName,
    Value<int>? quantity,
    Value<DeckSection>? section,
    Value<bool>? isShared,
    Value<bool>? isUnowned,
    Value<bool>? printingSpecified,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DeckEntriesCompanion(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      scryfallId: scryfallId ?? this.scryfallId,
      finish: finish ?? this.finish,
      cardName: cardName ?? this.cardName,
      quantity: quantity ?? this.quantity,
      section: section ?? this.section,
      isShared: isShared ?? this.isShared,
      isUnowned: isUnowned ?? this.isUnowned,
      printingSpecified: printingSpecified ?? this.printingSpecified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (scryfallId.present) {
      map['scryfall_id'] = Variable<String>(scryfallId.value);
    }
    if (finish.present) {
      map['finish'] = Variable<String>(
        $DeckEntriesTable.$converterfinishn.toSql(finish.value),
      );
    }
    if (cardName.present) {
      map['card_name'] = Variable<String>(cardName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (section.present) {
      map['section'] = Variable<String>(
        $DeckEntriesTable.$convertersection.toSql(section.value),
      );
    }
    if (isShared.present) {
      map['is_shared'] = Variable<bool>(isShared.value);
    }
    if (isUnowned.present) {
      map['is_unowned'] = Variable<bool>(isUnowned.value);
    }
    if (printingSpecified.present) {
      map['printing_specified'] = Variable<bool>(printingSpecified.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeckEntriesCompanion(')
          ..write('id: $id, ')
          ..write('deckId: $deckId, ')
          ..write('scryfallId: $scryfallId, ')
          ..write('finish: $finish, ')
          ..write('cardName: $cardName, ')
          ..write('quantity: $quantity, ')
          ..write('section: $section, ')
          ..write('isShared: $isShared, ')
          ..write('isUnowned: $isUnowned, ')
          ..write('printingSpecified: $printingSpecified, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserDatabase extends GeneratedDatabase {
  _$UserDatabase(QueryExecutor e) : super(e);
  $UserDatabaseManager get managers => $UserDatabaseManager(this);
  late final $StacksTable stacks = $StacksTable(this);
  late final $DecksTable decks = $DecksTable(this);
  late final $DeckEntriesTable deckEntries = $DeckEntriesTable(this);
  late final Index idxStacksScryfallId = Index(
    'idx_stacks_scryfall_id',
    'CREATE INDEX idx_stacks_scryfall_id ON stacks (scryfall_id)',
  );
  late final Index idxStacksProvenance = Index(
    'idx_stacks_provenance',
    'CREATE INDEX idx_stacks_provenance ON stacks (provenance)',
  );
  late final Index idxDeckEntriesDeckId = Index(
    'idx_deck_entries_deck_id',
    'CREATE INDEX idx_deck_entries_deck_id ON deck_entries (deck_id)',
  );
  late final Index idxDeckEntriesScryfallId = Index(
    'idx_deck_entries_scryfall_id',
    'CREATE INDEX idx_deck_entries_scryfall_id ON deck_entries (scryfall_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    stacks,
    decks,
    deckEntries,
    idxStacksScryfallId,
    idxStacksProvenance,
    idxDeckEntriesDeckId,
    idxDeckEntriesScryfallId,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'decks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('deck_entries', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$StacksTableCreateCompanionBuilder =
    StacksCompanion Function({
      required String id,
      required String scryfallId,
      required Finish finish,
      required int quantity,
      Value<String?> condition,
      Value<String?> language,
      required String provenance,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$StacksTableUpdateCompanionBuilder =
    StacksCompanion Function({
      Value<String> id,
      Value<String> scryfallId,
      Value<Finish> finish,
      Value<int> quantity,
      Value<String?> condition,
      Value<String?> language,
      Value<String> provenance,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$StacksTableFilterComposer
    extends Composer<_$UserDatabase, $StacksTable> {
  $$StacksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scryfallId => $composableBuilder(
    column: $table.scryfallId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Finish, Finish, String> get finish =>
      $composableBuilder(
        column: $table.finish,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StacksTableOrderingComposer
    extends Composer<_$UserDatabase, $StacksTable> {
  $$StacksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scryfallId => $composableBuilder(
    column: $table.scryfallId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finish => $composableBuilder(
    column: $table.finish,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get condition => $composableBuilder(
    column: $table.condition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StacksTableAnnotationComposer
    extends Composer<_$UserDatabase, $StacksTable> {
  $$StacksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scryfallId => $composableBuilder(
    column: $table.scryfallId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Finish, String> get finish =>
      $composableBuilder(column: $table.finish, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get condition =>
      $composableBuilder(column: $table.condition, builder: (column) => column);

  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StacksTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $StacksTable,
          StackRow,
          $$StacksTableFilterComposer,
          $$StacksTableOrderingComposer,
          $$StacksTableAnnotationComposer,
          $$StacksTableCreateCompanionBuilder,
          $$StacksTableUpdateCompanionBuilder,
          (StackRow, BaseReferences<_$UserDatabase, $StacksTable, StackRow>),
          StackRow,
          PrefetchHooks Function()
        > {
  $$StacksTableTableManager(_$UserDatabase db, $StacksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StacksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StacksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StacksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scryfallId = const Value.absent(),
                Value<Finish> finish = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String?> condition = const Value.absent(),
                Value<String?> language = const Value.absent(),
                Value<String> provenance = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StacksCompanion(
                id: id,
                scryfallId: scryfallId,
                finish: finish,
                quantity: quantity,
                condition: condition,
                language: language,
                provenance: provenance,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scryfallId,
                required Finish finish,
                required int quantity,
                Value<String?> condition = const Value.absent(),
                Value<String?> language = const Value.absent(),
                required String provenance,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StacksCompanion.insert(
                id: id,
                scryfallId: scryfallId,
                finish: finish,
                quantity: quantity,
                condition: condition,
                language: language,
                provenance: provenance,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StacksTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $StacksTable,
      StackRow,
      $$StacksTableFilterComposer,
      $$StacksTableOrderingComposer,
      $$StacksTableAnnotationComposer,
      $$StacksTableCreateCompanionBuilder,
      $$StacksTableUpdateCompanionBuilder,
      (StackRow, BaseReferences<_$UserDatabase, $StacksTable, StackRow>),
      StackRow,
      PrefetchHooks Function()
    >;
typedef $$DecksTableCreateCompanionBuilder =
    DecksCompanion Function({
      required String id,
      required String name,
      Value<String?> format,
      Value<bool> isAssembled,
      Value<bool> isShared,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DecksTableUpdateCompanionBuilder =
    DecksCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> format,
      Value<bool> isAssembled,
      Value<bool> isShared,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$DecksTableReferences
    extends BaseReferences<_$UserDatabase, $DecksTable, Deck> {
  $$DecksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DeckEntriesTable, List<DeckEntryRow>>
  _deckEntriesRefsTable(_$UserDatabase db) => MultiTypedResultKey.fromTable(
    db.deckEntries,
    aliasName: $_aliasNameGenerator(db.decks.id, db.deckEntries.deckId),
  );

  $$DeckEntriesTableProcessedTableManager get deckEntriesRefs {
    final manager = $$DeckEntriesTableTableManager(
      $_db,
      $_db.deckEntries,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_deckEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DecksTableFilterComposer extends Composer<_$UserDatabase, $DecksTable> {
  $$DecksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAssembled => $composableBuilder(
    column: $table.isAssembled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isShared => $composableBuilder(
    column: $table.isShared,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> deckEntriesRefs(
    Expression<bool> Function($$DeckEntriesTableFilterComposer f) f,
  ) {
    final $$DeckEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deckEntries,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeckEntriesTableFilterComposer(
            $db: $db,
            $table: $db.deckEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DecksTableOrderingComposer
    extends Composer<_$UserDatabase, $DecksTable> {
  $$DecksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAssembled => $composableBuilder(
    column: $table.isAssembled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isShared => $composableBuilder(
    column: $table.isShared,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DecksTableAnnotationComposer
    extends Composer<_$UserDatabase, $DecksTable> {
  $$DecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<bool> get isAssembled => $composableBuilder(
    column: $table.isAssembled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isShared =>
      $composableBuilder(column: $table.isShared, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> deckEntriesRefs<T extends Object>(
    Expression<T> Function($$DeckEntriesTableAnnotationComposer a) f,
  ) {
    final $$DeckEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deckEntries,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeckEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.deckEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DecksTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $DecksTable,
          Deck,
          $$DecksTableFilterComposer,
          $$DecksTableOrderingComposer,
          $$DecksTableAnnotationComposer,
          $$DecksTableCreateCompanionBuilder,
          $$DecksTableUpdateCompanionBuilder,
          (Deck, $$DecksTableReferences),
          Deck,
          PrefetchHooks Function({bool deckEntriesRefs})
        > {
  $$DecksTableTableManager(_$UserDatabase db, $DecksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> format = const Value.absent(),
                Value<bool> isAssembled = const Value.absent(),
                Value<bool> isShared = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DecksCompanion(
                id: id,
                name: name,
                format: format,
                isAssembled: isAssembled,
                isShared: isShared,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> format = const Value.absent(),
                Value<bool> isAssembled = const Value.absent(),
                Value<bool> isShared = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DecksCompanion.insert(
                id: id,
                name: name,
                format: format,
                isAssembled: isAssembled,
                isShared: isShared,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$DecksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({deckEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (deckEntriesRefs) db.deckEntries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (deckEntriesRefs)
                    await $_getPrefetchedData<Deck, $DecksTable, DeckEntryRow>(
                      currentTable: table,
                      referencedTable: $$DecksTableReferences
                          ._deckEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DecksTableReferences(db, table, p0).deckEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.deckId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DecksTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $DecksTable,
      Deck,
      $$DecksTableFilterComposer,
      $$DecksTableOrderingComposer,
      $$DecksTableAnnotationComposer,
      $$DecksTableCreateCompanionBuilder,
      $$DecksTableUpdateCompanionBuilder,
      (Deck, $$DecksTableReferences),
      Deck,
      PrefetchHooks Function({bool deckEntriesRefs})
    >;
typedef $$DeckEntriesTableCreateCompanionBuilder =
    DeckEntriesCompanion Function({
      required String id,
      required String deckId,
      required String scryfallId,
      Value<Finish?> finish,
      required String cardName,
      required int quantity,
      required DeckSection section,
      Value<bool> isShared,
      Value<bool> isUnowned,
      Value<bool> printingSpecified,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$DeckEntriesTableUpdateCompanionBuilder =
    DeckEntriesCompanion Function({
      Value<String> id,
      Value<String> deckId,
      Value<String> scryfallId,
      Value<Finish?> finish,
      Value<String> cardName,
      Value<int> quantity,
      Value<DeckSection> section,
      Value<bool> isShared,
      Value<bool> isUnowned,
      Value<bool> printingSpecified,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$DeckEntriesTableReferences
    extends BaseReferences<_$UserDatabase, $DeckEntriesTable, DeckEntryRow> {
  $$DeckEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DecksTable _deckIdTable(_$UserDatabase db) => db.decks.createAlias(
    $_aliasNameGenerator(db.deckEntries.deckId, db.decks.id),
  );

  $$DecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<String>('deck_id')!;

    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DeckEntriesTableFilterComposer
    extends Composer<_$UserDatabase, $DeckEntriesTable> {
  $$DeckEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scryfallId => $composableBuilder(
    column: $table.scryfallId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Finish?, Finish, String> get finish =>
      $composableBuilder(
        column: $table.finish,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get cardName => $composableBuilder(
    column: $table.cardName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DeckSection, DeckSection, String>
  get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get isShared => $composableBuilder(
    column: $table.isShared,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUnowned => $composableBuilder(
    column: $table.isUnowned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get printingSpecified => $composableBuilder(
    column: $table.printingSpecified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeckEntriesTableOrderingComposer
    extends Composer<_$UserDatabase, $DeckEntriesTable> {
  $$DeckEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scryfallId => $composableBuilder(
    column: $table.scryfallId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finish => $composableBuilder(
    column: $table.finish,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cardName => $composableBuilder(
    column: $table.cardName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isShared => $composableBuilder(
    column: $table.isShared,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUnowned => $composableBuilder(
    column: $table.isUnowned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get printingSpecified => $composableBuilder(
    column: $table.printingSpecified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableOrderingComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeckEntriesTableAnnotationComposer
    extends Composer<_$UserDatabase, $DeckEntriesTable> {
  $$DeckEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scryfallId => $composableBuilder(
    column: $table.scryfallId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Finish?, String> get finish =>
      $composableBuilder(column: $table.finish, builder: (column) => column);

  GeneratedColumn<String> get cardName =>
      $composableBuilder(column: $table.cardName, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DeckSection, String> get section =>
      $composableBuilder(column: $table.section, builder: (column) => column);

  GeneratedColumn<bool> get isShared =>
      $composableBuilder(column: $table.isShared, builder: (column) => column);

  GeneratedColumn<bool> get isUnowned =>
      $composableBuilder(column: $table.isUnowned, builder: (column) => column);

  GeneratedColumn<bool> get printingSpecified => $composableBuilder(
    column: $table.printingSpecified,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeckEntriesTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $DeckEntriesTable,
          DeckEntryRow,
          $$DeckEntriesTableFilterComposer,
          $$DeckEntriesTableOrderingComposer,
          $$DeckEntriesTableAnnotationComposer,
          $$DeckEntriesTableCreateCompanionBuilder,
          $$DeckEntriesTableUpdateCompanionBuilder,
          (DeckEntryRow, $$DeckEntriesTableReferences),
          DeckEntryRow,
          PrefetchHooks Function({bool deckId})
        > {
  $$DeckEntriesTableTableManager(_$UserDatabase db, $DeckEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeckEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeckEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeckEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deckId = const Value.absent(),
                Value<String> scryfallId = const Value.absent(),
                Value<Finish?> finish = const Value.absent(),
                Value<String> cardName = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<DeckSection> section = const Value.absent(),
                Value<bool> isShared = const Value.absent(),
                Value<bool> isUnowned = const Value.absent(),
                Value<bool> printingSpecified = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeckEntriesCompanion(
                id: id,
                deckId: deckId,
                scryfallId: scryfallId,
                finish: finish,
                cardName: cardName,
                quantity: quantity,
                section: section,
                isShared: isShared,
                isUnowned: isUnowned,
                printingSpecified: printingSpecified,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deckId,
                required String scryfallId,
                Value<Finish?> finish = const Value.absent(),
                required String cardName,
                required int quantity,
                required DeckSection section,
                Value<bool> isShared = const Value.absent(),
                Value<bool> isUnowned = const Value.absent(),
                Value<bool> printingSpecified = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => DeckEntriesCompanion.insert(
                id: id,
                deckId: deckId,
                scryfallId: scryfallId,
                finish: finish,
                cardName: cardName,
                quantity: quantity,
                section: section,
                isShared: isShared,
                isUnowned: isUnowned,
                printingSpecified: printingSpecified,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DeckEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deckId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (deckId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deckId,
                                referencedTable: $$DeckEntriesTableReferences
                                    ._deckIdTable(db),
                                referencedColumn: $$DeckEntriesTableReferences
                                    ._deckIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DeckEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $DeckEntriesTable,
      DeckEntryRow,
      $$DeckEntriesTableFilterComposer,
      $$DeckEntriesTableOrderingComposer,
      $$DeckEntriesTableAnnotationComposer,
      $$DeckEntriesTableCreateCompanionBuilder,
      $$DeckEntriesTableUpdateCompanionBuilder,
      (DeckEntryRow, $$DeckEntriesTableReferences),
      DeckEntryRow,
      PrefetchHooks Function({bool deckId})
    >;

class $UserDatabaseManager {
  final _$UserDatabase _db;
  $UserDatabaseManager(this._db);
  $$StacksTableTableManager get stacks =>
      $$StacksTableTableManager(_db, _db.stacks);
  $$DecksTableTableManager get decks =>
      $$DecksTableTableManager(_db, _db.decks);
  $$DeckEntriesTableTableManager get deckEntries =>
      $$DeckEntriesTableTableManager(_db, _db.deckEntries);
}
