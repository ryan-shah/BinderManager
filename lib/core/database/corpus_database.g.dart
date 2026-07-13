// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'corpus_database.dart';

// ignore_for_file: type=lint
class $CardsTable extends Cards with TableInfo<$CardsTable, Card> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _oracleIdMeta = const VerificationMeta(
    'oracleId',
  );
  @override
  late final GeneratedColumn<String> oracleId = GeneratedColumn<String>(
    'oracle_id',
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
  static const VerificationMeta _manaCostMeta = const VerificationMeta(
    'manaCost',
  );
  @override
  late final GeneratedColumn<String> manaCost = GeneratedColumn<String>(
    'mana_cost',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cmcMeta = const VerificationMeta('cmc');
  @override
  late final GeneratedColumn<double> cmc = GeneratedColumn<double>(
    'cmc',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeLineMeta = const VerificationMeta(
    'typeLine',
  );
  @override
  late final GeneratedColumn<String> typeLine = GeneratedColumn<String>(
    'type_line',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _oracleTextMeta = const VerificationMeta(
    'oracleText',
  );
  @override
  late final GeneratedColumn<String> oracleText = GeneratedColumn<String>(
    'oracle_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorsMeta = const VerificationMeta('colors');
  @override
  late final GeneratedColumn<String> colors = GeneratedColumn<String>(
    'colors',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorIdentityMeta = const VerificationMeta(
    'colorIdentity',
  );
  @override
  late final GeneratedColumn<String> colorIdentity = GeneratedColumn<String>(
    'color_identity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setCodeMeta = const VerificationMeta(
    'setCode',
  );
  @override
  late final GeneratedColumn<String> setCode = GeneratedColumn<String>(
    'set_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setNameMeta = const VerificationMeta(
    'setName',
  );
  @override
  late final GeneratedColumn<String> setName = GeneratedColumn<String>(
    'set_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectorNumberMeta = const VerificationMeta(
    'collectorNumber',
  );
  @override
  late final GeneratedColumn<String> collectorNumber = GeneratedColumn<String>(
    'collector_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rarityMeta = const VerificationMeta('rarity');
  @override
  late final GeneratedColumn<String> rarity = GeneratedColumn<String>(
    'rarity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishesMeta = const VerificationMeta(
    'finishes',
  );
  @override
  late final GeneratedColumn<String> finishes = GeneratedColumn<String>(
    'finishes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceUsdMeta = const VerificationMeta(
    'priceUsd',
  );
  @override
  late final GeneratedColumn<double> priceUsd = GeneratedColumn<double>(
    'price_usd',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceUsdFoilMeta = const VerificationMeta(
    'priceUsdFoil',
  );
  @override
  late final GeneratedColumn<double> priceUsdFoil = GeneratedColumn<double>(
    'price_usd_foil',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceUsdEtchedMeta = const VerificationMeta(
    'priceUsdEtched',
  );
  @override
  late final GeneratedColumn<double> priceUsdEtched = GeneratedColumn<double>(
    'price_usd_etched',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceEurMeta = const VerificationMeta(
    'priceEur',
  );
  @override
  late final GeneratedColumn<double> priceEur = GeneratedColumn<double>(
    'price_eur',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceEurFoilMeta = const VerificationMeta(
    'priceEurFoil',
  );
  @override
  late final GeneratedColumn<double> priceEurFoil = GeneratedColumn<double>(
    'price_eur_foil',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUriSmallMeta = const VerificationMeta(
    'imageUriSmall',
  );
  @override
  late final GeneratedColumn<String> imageUriSmall = GeneratedColumn<String>(
    'image_uri_small',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUriNormalMeta = const VerificationMeta(
    'imageUriNormal',
  );
  @override
  late final GeneratedColumn<String> imageUriNormal = GeneratedColumn<String>(
    'image_uri_normal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFullartMeta = const VerificationMeta(
    'isFullart',
  );
  @override
  late final GeneratedColumn<bool> isFullart = GeneratedColumn<bool>(
    'is_fullart',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_fullart" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPromoMeta = const VerificationMeta(
    'isPromo',
  );
  @override
  late final GeneratedColumn<bool> isPromo = GeneratedColumn<bool>(
    'is_promo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_promo" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _frameEffectsMeta = const VerificationMeta(
    'frameEffects',
  );
  @override
  late final GeneratedColumn<String> frameEffects = GeneratedColumn<String>(
    'frame_effects',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _securityStampMeta = const VerificationMeta(
    'securityStamp',
  );
  @override
  late final GeneratedColumn<String> securityStamp = GeneratedColumn<String>(
    'security_stamp',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _borderColorMeta = const VerificationMeta(
    'borderColor',
  );
  @override
  late final GeneratedColumn<String> borderColor = GeneratedColumn<String>(
    'border_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _layoutMeta = const VerificationMeta('layout');
  @override
  late final GeneratedColumn<String> layout = GeneratedColumn<String>(
    'layout',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _releasedAtMeta = const VerificationMeta(
    'releasedAt',
  );
  @override
  late final GeneratedColumn<String> releasedAt = GeneratedColumn<String>(
    'released_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    scryfallId,
    oracleId,
    name,
    manaCost,
    cmc,
    typeLine,
    oracleText,
    colors,
    colorIdentity,
    setCode,
    setName,
    collectorNumber,
    rarity,
    finishes,
    priceUsd,
    priceUsdFoil,
    priceUsdEtched,
    priceEur,
    priceEurFoil,
    imageUriSmall,
    imageUriNormal,
    isFullart,
    isPromo,
    frameEffects,
    securityStamp,
    borderColor,
    layout,
    releasedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<Card> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scryfall_id')) {
      context.handle(
        _scryfallIdMeta,
        scryfallId.isAcceptableOrUnknown(data['scryfall_id']!, _scryfallIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scryfallIdMeta);
    }
    if (data.containsKey('oracle_id')) {
      context.handle(
        _oracleIdMeta,
        oracleId.isAcceptableOrUnknown(data['oracle_id']!, _oracleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_oracleIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('mana_cost')) {
      context.handle(
        _manaCostMeta,
        manaCost.isAcceptableOrUnknown(data['mana_cost']!, _manaCostMeta),
      );
    }
    if (data.containsKey('cmc')) {
      context.handle(
        _cmcMeta,
        cmc.isAcceptableOrUnknown(data['cmc']!, _cmcMeta),
      );
    } else if (isInserting) {
      context.missing(_cmcMeta);
    }
    if (data.containsKey('type_line')) {
      context.handle(
        _typeLineMeta,
        typeLine.isAcceptableOrUnknown(data['type_line']!, _typeLineMeta),
      );
    } else if (isInserting) {
      context.missing(_typeLineMeta);
    }
    if (data.containsKey('oracle_text')) {
      context.handle(
        _oracleTextMeta,
        oracleText.isAcceptableOrUnknown(data['oracle_text']!, _oracleTextMeta),
      );
    }
    if (data.containsKey('colors')) {
      context.handle(
        _colorsMeta,
        colors.isAcceptableOrUnknown(data['colors']!, _colorsMeta),
      );
    }
    if (data.containsKey('color_identity')) {
      context.handle(
        _colorIdentityMeta,
        colorIdentity.isAcceptableOrUnknown(
          data['color_identity']!,
          _colorIdentityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_colorIdentityMeta);
    }
    if (data.containsKey('set_code')) {
      context.handle(
        _setCodeMeta,
        setCode.isAcceptableOrUnknown(data['set_code']!, _setCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_setCodeMeta);
    }
    if (data.containsKey('set_name')) {
      context.handle(
        _setNameMeta,
        setName.isAcceptableOrUnknown(data['set_name']!, _setNameMeta),
      );
    } else if (isInserting) {
      context.missing(_setNameMeta);
    }
    if (data.containsKey('collector_number')) {
      context.handle(
        _collectorNumberMeta,
        collectorNumber.isAcceptableOrUnknown(
          data['collector_number']!,
          _collectorNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectorNumberMeta);
    }
    if (data.containsKey('rarity')) {
      context.handle(
        _rarityMeta,
        rarity.isAcceptableOrUnknown(data['rarity']!, _rarityMeta),
      );
    } else if (isInserting) {
      context.missing(_rarityMeta);
    }
    if (data.containsKey('finishes')) {
      context.handle(
        _finishesMeta,
        finishes.isAcceptableOrUnknown(data['finishes']!, _finishesMeta),
      );
    } else if (isInserting) {
      context.missing(_finishesMeta);
    }
    if (data.containsKey('price_usd')) {
      context.handle(
        _priceUsdMeta,
        priceUsd.isAcceptableOrUnknown(data['price_usd']!, _priceUsdMeta),
      );
    }
    if (data.containsKey('price_usd_foil')) {
      context.handle(
        _priceUsdFoilMeta,
        priceUsdFoil.isAcceptableOrUnknown(
          data['price_usd_foil']!,
          _priceUsdFoilMeta,
        ),
      );
    }
    if (data.containsKey('price_usd_etched')) {
      context.handle(
        _priceUsdEtchedMeta,
        priceUsdEtched.isAcceptableOrUnknown(
          data['price_usd_etched']!,
          _priceUsdEtchedMeta,
        ),
      );
    }
    if (data.containsKey('price_eur')) {
      context.handle(
        _priceEurMeta,
        priceEur.isAcceptableOrUnknown(data['price_eur']!, _priceEurMeta),
      );
    }
    if (data.containsKey('price_eur_foil')) {
      context.handle(
        _priceEurFoilMeta,
        priceEurFoil.isAcceptableOrUnknown(
          data['price_eur_foil']!,
          _priceEurFoilMeta,
        ),
      );
    }
    if (data.containsKey('image_uri_small')) {
      context.handle(
        _imageUriSmallMeta,
        imageUriSmall.isAcceptableOrUnknown(
          data['image_uri_small']!,
          _imageUriSmallMeta,
        ),
      );
    }
    if (data.containsKey('image_uri_normal')) {
      context.handle(
        _imageUriNormalMeta,
        imageUriNormal.isAcceptableOrUnknown(
          data['image_uri_normal']!,
          _imageUriNormalMeta,
        ),
      );
    }
    if (data.containsKey('is_fullart')) {
      context.handle(
        _isFullartMeta,
        isFullart.isAcceptableOrUnknown(data['is_fullart']!, _isFullartMeta),
      );
    }
    if (data.containsKey('is_promo')) {
      context.handle(
        _isPromoMeta,
        isPromo.isAcceptableOrUnknown(data['is_promo']!, _isPromoMeta),
      );
    }
    if (data.containsKey('frame_effects')) {
      context.handle(
        _frameEffectsMeta,
        frameEffects.isAcceptableOrUnknown(
          data['frame_effects']!,
          _frameEffectsMeta,
        ),
      );
    }
    if (data.containsKey('security_stamp')) {
      context.handle(
        _securityStampMeta,
        securityStamp.isAcceptableOrUnknown(
          data['security_stamp']!,
          _securityStampMeta,
        ),
      );
    }
    if (data.containsKey('border_color')) {
      context.handle(
        _borderColorMeta,
        borderColor.isAcceptableOrUnknown(
          data['border_color']!,
          _borderColorMeta,
        ),
      );
    }
    if (data.containsKey('layout')) {
      context.handle(
        _layoutMeta,
        layout.isAcceptableOrUnknown(data['layout']!, _layoutMeta),
      );
    } else if (isInserting) {
      context.missing(_layoutMeta);
    }
    if (data.containsKey('released_at')) {
      context.handle(
        _releasedAtMeta,
        releasedAt.isAcceptableOrUnknown(data['released_at']!, _releasedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_releasedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scryfallId};
  @override
  Card map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Card(
      scryfallId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scryfall_id'],
      )!,
      oracleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}oracle_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      manaCost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mana_cost'],
      ),
      cmc: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cmc'],
      )!,
      typeLine: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type_line'],
      )!,
      oracleText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}oracle_text'],
      ),
      colors: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}colors'],
      ),
      colorIdentity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_identity'],
      )!,
      setCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_code'],
      )!,
      setName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_name'],
      )!,
      collectorNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collector_number'],
      )!,
      rarity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rarity'],
      )!,
      finishes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}finishes'],
      )!,
      priceUsd: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_usd'],
      ),
      priceUsdFoil: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_usd_foil'],
      ),
      priceUsdEtched: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_usd_etched'],
      ),
      priceEur: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_eur'],
      ),
      priceEurFoil: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_eur_foil'],
      ),
      imageUriSmall: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_uri_small'],
      ),
      imageUriNormal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_uri_normal'],
      ),
      isFullart: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_fullart'],
      )!,
      isPromo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_promo'],
      )!,
      frameEffects: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frame_effects'],
      ),
      securityStamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}security_stamp'],
      ),
      borderColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}border_color'],
      ),
      layout: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layout'],
      )!,
      releasedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}released_at'],
      )!,
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }
}

class Card extends DataClass implements Insertable<Card> {
  final String scryfallId;
  final String oracleId;
  final String name;
  final String? manaCost;
  final double cmc;
  final String typeLine;
  final String? oracleText;
  final String? colors;
  final String colorIdentity;
  final String setCode;
  final String setName;
  final String collectorNumber;
  final String rarity;
  final String finishes;
  final double? priceUsd;
  final double? priceUsdFoil;
  final double? priceUsdEtched;
  final double? priceEur;
  final double? priceEurFoil;
  final String? imageUriSmall;
  final String? imageUriNormal;
  final bool isFullart;
  final bool isPromo;
  final String? frameEffects;
  final String? securityStamp;
  final String? borderColor;
  final String layout;
  final String releasedAt;
  const Card({
    required this.scryfallId,
    required this.oracleId,
    required this.name,
    this.manaCost,
    required this.cmc,
    required this.typeLine,
    this.oracleText,
    this.colors,
    required this.colorIdentity,
    required this.setCode,
    required this.setName,
    required this.collectorNumber,
    required this.rarity,
    required this.finishes,
    this.priceUsd,
    this.priceUsdFoil,
    this.priceUsdEtched,
    this.priceEur,
    this.priceEurFoil,
    this.imageUriSmall,
    this.imageUriNormal,
    required this.isFullart,
    required this.isPromo,
    this.frameEffects,
    this.securityStamp,
    this.borderColor,
    required this.layout,
    required this.releasedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['scryfall_id'] = Variable<String>(scryfallId);
    map['oracle_id'] = Variable<String>(oracleId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || manaCost != null) {
      map['mana_cost'] = Variable<String>(manaCost);
    }
    map['cmc'] = Variable<double>(cmc);
    map['type_line'] = Variable<String>(typeLine);
    if (!nullToAbsent || oracleText != null) {
      map['oracle_text'] = Variable<String>(oracleText);
    }
    if (!nullToAbsent || colors != null) {
      map['colors'] = Variable<String>(colors);
    }
    map['color_identity'] = Variable<String>(colorIdentity);
    map['set_code'] = Variable<String>(setCode);
    map['set_name'] = Variable<String>(setName);
    map['collector_number'] = Variable<String>(collectorNumber);
    map['rarity'] = Variable<String>(rarity);
    map['finishes'] = Variable<String>(finishes);
    if (!nullToAbsent || priceUsd != null) {
      map['price_usd'] = Variable<double>(priceUsd);
    }
    if (!nullToAbsent || priceUsdFoil != null) {
      map['price_usd_foil'] = Variable<double>(priceUsdFoil);
    }
    if (!nullToAbsent || priceUsdEtched != null) {
      map['price_usd_etched'] = Variable<double>(priceUsdEtched);
    }
    if (!nullToAbsent || priceEur != null) {
      map['price_eur'] = Variable<double>(priceEur);
    }
    if (!nullToAbsent || priceEurFoil != null) {
      map['price_eur_foil'] = Variable<double>(priceEurFoil);
    }
    if (!nullToAbsent || imageUriSmall != null) {
      map['image_uri_small'] = Variable<String>(imageUriSmall);
    }
    if (!nullToAbsent || imageUriNormal != null) {
      map['image_uri_normal'] = Variable<String>(imageUriNormal);
    }
    map['is_fullart'] = Variable<bool>(isFullart);
    map['is_promo'] = Variable<bool>(isPromo);
    if (!nullToAbsent || frameEffects != null) {
      map['frame_effects'] = Variable<String>(frameEffects);
    }
    if (!nullToAbsent || securityStamp != null) {
      map['security_stamp'] = Variable<String>(securityStamp);
    }
    if (!nullToAbsent || borderColor != null) {
      map['border_color'] = Variable<String>(borderColor);
    }
    map['layout'] = Variable<String>(layout);
    map['released_at'] = Variable<String>(releasedAt);
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      scryfallId: Value(scryfallId),
      oracleId: Value(oracleId),
      name: Value(name),
      manaCost: manaCost == null && nullToAbsent
          ? const Value.absent()
          : Value(manaCost),
      cmc: Value(cmc),
      typeLine: Value(typeLine),
      oracleText: oracleText == null && nullToAbsent
          ? const Value.absent()
          : Value(oracleText),
      colors: colors == null && nullToAbsent
          ? const Value.absent()
          : Value(colors),
      colorIdentity: Value(colorIdentity),
      setCode: Value(setCode),
      setName: Value(setName),
      collectorNumber: Value(collectorNumber),
      rarity: Value(rarity),
      finishes: Value(finishes),
      priceUsd: priceUsd == null && nullToAbsent
          ? const Value.absent()
          : Value(priceUsd),
      priceUsdFoil: priceUsdFoil == null && nullToAbsent
          ? const Value.absent()
          : Value(priceUsdFoil),
      priceUsdEtched: priceUsdEtched == null && nullToAbsent
          ? const Value.absent()
          : Value(priceUsdEtched),
      priceEur: priceEur == null && nullToAbsent
          ? const Value.absent()
          : Value(priceEur),
      priceEurFoil: priceEurFoil == null && nullToAbsent
          ? const Value.absent()
          : Value(priceEurFoil),
      imageUriSmall: imageUriSmall == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUriSmall),
      imageUriNormal: imageUriNormal == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUriNormal),
      isFullart: Value(isFullart),
      isPromo: Value(isPromo),
      frameEffects: frameEffects == null && nullToAbsent
          ? const Value.absent()
          : Value(frameEffects),
      securityStamp: securityStamp == null && nullToAbsent
          ? const Value.absent()
          : Value(securityStamp),
      borderColor: borderColor == null && nullToAbsent
          ? const Value.absent()
          : Value(borderColor),
      layout: Value(layout),
      releasedAt: Value(releasedAt),
    );
  }

  factory Card.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Card(
      scryfallId: serializer.fromJson<String>(json['scryfallId']),
      oracleId: serializer.fromJson<String>(json['oracleId']),
      name: serializer.fromJson<String>(json['name']),
      manaCost: serializer.fromJson<String?>(json['manaCost']),
      cmc: serializer.fromJson<double>(json['cmc']),
      typeLine: serializer.fromJson<String>(json['typeLine']),
      oracleText: serializer.fromJson<String?>(json['oracleText']),
      colors: serializer.fromJson<String?>(json['colors']),
      colorIdentity: serializer.fromJson<String>(json['colorIdentity']),
      setCode: serializer.fromJson<String>(json['setCode']),
      setName: serializer.fromJson<String>(json['setName']),
      collectorNumber: serializer.fromJson<String>(json['collectorNumber']),
      rarity: serializer.fromJson<String>(json['rarity']),
      finishes: serializer.fromJson<String>(json['finishes']),
      priceUsd: serializer.fromJson<double?>(json['priceUsd']),
      priceUsdFoil: serializer.fromJson<double?>(json['priceUsdFoil']),
      priceUsdEtched: serializer.fromJson<double?>(json['priceUsdEtched']),
      priceEur: serializer.fromJson<double?>(json['priceEur']),
      priceEurFoil: serializer.fromJson<double?>(json['priceEurFoil']),
      imageUriSmall: serializer.fromJson<String?>(json['imageUriSmall']),
      imageUriNormal: serializer.fromJson<String?>(json['imageUriNormal']),
      isFullart: serializer.fromJson<bool>(json['isFullart']),
      isPromo: serializer.fromJson<bool>(json['isPromo']),
      frameEffects: serializer.fromJson<String?>(json['frameEffects']),
      securityStamp: serializer.fromJson<String?>(json['securityStamp']),
      borderColor: serializer.fromJson<String?>(json['borderColor']),
      layout: serializer.fromJson<String>(json['layout']),
      releasedAt: serializer.fromJson<String>(json['releasedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scryfallId': serializer.toJson<String>(scryfallId),
      'oracleId': serializer.toJson<String>(oracleId),
      'name': serializer.toJson<String>(name),
      'manaCost': serializer.toJson<String?>(manaCost),
      'cmc': serializer.toJson<double>(cmc),
      'typeLine': serializer.toJson<String>(typeLine),
      'oracleText': serializer.toJson<String?>(oracleText),
      'colors': serializer.toJson<String?>(colors),
      'colorIdentity': serializer.toJson<String>(colorIdentity),
      'setCode': serializer.toJson<String>(setCode),
      'setName': serializer.toJson<String>(setName),
      'collectorNumber': serializer.toJson<String>(collectorNumber),
      'rarity': serializer.toJson<String>(rarity),
      'finishes': serializer.toJson<String>(finishes),
      'priceUsd': serializer.toJson<double?>(priceUsd),
      'priceUsdFoil': serializer.toJson<double?>(priceUsdFoil),
      'priceUsdEtched': serializer.toJson<double?>(priceUsdEtched),
      'priceEur': serializer.toJson<double?>(priceEur),
      'priceEurFoil': serializer.toJson<double?>(priceEurFoil),
      'imageUriSmall': serializer.toJson<String?>(imageUriSmall),
      'imageUriNormal': serializer.toJson<String?>(imageUriNormal),
      'isFullart': serializer.toJson<bool>(isFullart),
      'isPromo': serializer.toJson<bool>(isPromo),
      'frameEffects': serializer.toJson<String?>(frameEffects),
      'securityStamp': serializer.toJson<String?>(securityStamp),
      'borderColor': serializer.toJson<String?>(borderColor),
      'layout': serializer.toJson<String>(layout),
      'releasedAt': serializer.toJson<String>(releasedAt),
    };
  }

  Card copyWith({
    String? scryfallId,
    String? oracleId,
    String? name,
    Value<String?> manaCost = const Value.absent(),
    double? cmc,
    String? typeLine,
    Value<String?> oracleText = const Value.absent(),
    Value<String?> colors = const Value.absent(),
    String? colorIdentity,
    String? setCode,
    String? setName,
    String? collectorNumber,
    String? rarity,
    String? finishes,
    Value<double?> priceUsd = const Value.absent(),
    Value<double?> priceUsdFoil = const Value.absent(),
    Value<double?> priceUsdEtched = const Value.absent(),
    Value<double?> priceEur = const Value.absent(),
    Value<double?> priceEurFoil = const Value.absent(),
    Value<String?> imageUriSmall = const Value.absent(),
    Value<String?> imageUriNormal = const Value.absent(),
    bool? isFullart,
    bool? isPromo,
    Value<String?> frameEffects = const Value.absent(),
    Value<String?> securityStamp = const Value.absent(),
    Value<String?> borderColor = const Value.absent(),
    String? layout,
    String? releasedAt,
  }) => Card(
    scryfallId: scryfallId ?? this.scryfallId,
    oracleId: oracleId ?? this.oracleId,
    name: name ?? this.name,
    manaCost: manaCost.present ? manaCost.value : this.manaCost,
    cmc: cmc ?? this.cmc,
    typeLine: typeLine ?? this.typeLine,
    oracleText: oracleText.present ? oracleText.value : this.oracleText,
    colors: colors.present ? colors.value : this.colors,
    colorIdentity: colorIdentity ?? this.colorIdentity,
    setCode: setCode ?? this.setCode,
    setName: setName ?? this.setName,
    collectorNumber: collectorNumber ?? this.collectorNumber,
    rarity: rarity ?? this.rarity,
    finishes: finishes ?? this.finishes,
    priceUsd: priceUsd.present ? priceUsd.value : this.priceUsd,
    priceUsdFoil: priceUsdFoil.present ? priceUsdFoil.value : this.priceUsdFoil,
    priceUsdEtched: priceUsdEtched.present
        ? priceUsdEtched.value
        : this.priceUsdEtched,
    priceEur: priceEur.present ? priceEur.value : this.priceEur,
    priceEurFoil: priceEurFoil.present ? priceEurFoil.value : this.priceEurFoil,
    imageUriSmall: imageUriSmall.present
        ? imageUriSmall.value
        : this.imageUriSmall,
    imageUriNormal: imageUriNormal.present
        ? imageUriNormal.value
        : this.imageUriNormal,
    isFullart: isFullart ?? this.isFullart,
    isPromo: isPromo ?? this.isPromo,
    frameEffects: frameEffects.present ? frameEffects.value : this.frameEffects,
    securityStamp: securityStamp.present
        ? securityStamp.value
        : this.securityStamp,
    borderColor: borderColor.present ? borderColor.value : this.borderColor,
    layout: layout ?? this.layout,
    releasedAt: releasedAt ?? this.releasedAt,
  );
  Card copyWithCompanion(CardsCompanion data) {
    return Card(
      scryfallId: data.scryfallId.present
          ? data.scryfallId.value
          : this.scryfallId,
      oracleId: data.oracleId.present ? data.oracleId.value : this.oracleId,
      name: data.name.present ? data.name.value : this.name,
      manaCost: data.manaCost.present ? data.manaCost.value : this.manaCost,
      cmc: data.cmc.present ? data.cmc.value : this.cmc,
      typeLine: data.typeLine.present ? data.typeLine.value : this.typeLine,
      oracleText: data.oracleText.present
          ? data.oracleText.value
          : this.oracleText,
      colors: data.colors.present ? data.colors.value : this.colors,
      colorIdentity: data.colorIdentity.present
          ? data.colorIdentity.value
          : this.colorIdentity,
      setCode: data.setCode.present ? data.setCode.value : this.setCode,
      setName: data.setName.present ? data.setName.value : this.setName,
      collectorNumber: data.collectorNumber.present
          ? data.collectorNumber.value
          : this.collectorNumber,
      rarity: data.rarity.present ? data.rarity.value : this.rarity,
      finishes: data.finishes.present ? data.finishes.value : this.finishes,
      priceUsd: data.priceUsd.present ? data.priceUsd.value : this.priceUsd,
      priceUsdFoil: data.priceUsdFoil.present
          ? data.priceUsdFoil.value
          : this.priceUsdFoil,
      priceUsdEtched: data.priceUsdEtched.present
          ? data.priceUsdEtched.value
          : this.priceUsdEtched,
      priceEur: data.priceEur.present ? data.priceEur.value : this.priceEur,
      priceEurFoil: data.priceEurFoil.present
          ? data.priceEurFoil.value
          : this.priceEurFoil,
      imageUriSmall: data.imageUriSmall.present
          ? data.imageUriSmall.value
          : this.imageUriSmall,
      imageUriNormal: data.imageUriNormal.present
          ? data.imageUriNormal.value
          : this.imageUriNormal,
      isFullart: data.isFullart.present ? data.isFullart.value : this.isFullart,
      isPromo: data.isPromo.present ? data.isPromo.value : this.isPromo,
      frameEffects: data.frameEffects.present
          ? data.frameEffects.value
          : this.frameEffects,
      securityStamp: data.securityStamp.present
          ? data.securityStamp.value
          : this.securityStamp,
      borderColor: data.borderColor.present
          ? data.borderColor.value
          : this.borderColor,
      layout: data.layout.present ? data.layout.value : this.layout,
      releasedAt: data.releasedAt.present
          ? data.releasedAt.value
          : this.releasedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Card(')
          ..write('scryfallId: $scryfallId, ')
          ..write('oracleId: $oracleId, ')
          ..write('name: $name, ')
          ..write('manaCost: $manaCost, ')
          ..write('cmc: $cmc, ')
          ..write('typeLine: $typeLine, ')
          ..write('oracleText: $oracleText, ')
          ..write('colors: $colors, ')
          ..write('colorIdentity: $colorIdentity, ')
          ..write('setCode: $setCode, ')
          ..write('setName: $setName, ')
          ..write('collectorNumber: $collectorNumber, ')
          ..write('rarity: $rarity, ')
          ..write('finishes: $finishes, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('priceUsdFoil: $priceUsdFoil, ')
          ..write('priceUsdEtched: $priceUsdEtched, ')
          ..write('priceEur: $priceEur, ')
          ..write('priceEurFoil: $priceEurFoil, ')
          ..write('imageUriSmall: $imageUriSmall, ')
          ..write('imageUriNormal: $imageUriNormal, ')
          ..write('isFullart: $isFullart, ')
          ..write('isPromo: $isPromo, ')
          ..write('frameEffects: $frameEffects, ')
          ..write('securityStamp: $securityStamp, ')
          ..write('borderColor: $borderColor, ')
          ..write('layout: $layout, ')
          ..write('releasedAt: $releasedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    scryfallId,
    oracleId,
    name,
    manaCost,
    cmc,
    typeLine,
    oracleText,
    colors,
    colorIdentity,
    setCode,
    setName,
    collectorNumber,
    rarity,
    finishes,
    priceUsd,
    priceUsdFoil,
    priceUsdEtched,
    priceEur,
    priceEurFoil,
    imageUriSmall,
    imageUriNormal,
    isFullart,
    isPromo,
    frameEffects,
    securityStamp,
    borderColor,
    layout,
    releasedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Card &&
          other.scryfallId == this.scryfallId &&
          other.oracleId == this.oracleId &&
          other.name == this.name &&
          other.manaCost == this.manaCost &&
          other.cmc == this.cmc &&
          other.typeLine == this.typeLine &&
          other.oracleText == this.oracleText &&
          other.colors == this.colors &&
          other.colorIdentity == this.colorIdentity &&
          other.setCode == this.setCode &&
          other.setName == this.setName &&
          other.collectorNumber == this.collectorNumber &&
          other.rarity == this.rarity &&
          other.finishes == this.finishes &&
          other.priceUsd == this.priceUsd &&
          other.priceUsdFoil == this.priceUsdFoil &&
          other.priceUsdEtched == this.priceUsdEtched &&
          other.priceEur == this.priceEur &&
          other.priceEurFoil == this.priceEurFoil &&
          other.imageUriSmall == this.imageUriSmall &&
          other.imageUriNormal == this.imageUriNormal &&
          other.isFullart == this.isFullart &&
          other.isPromo == this.isPromo &&
          other.frameEffects == this.frameEffects &&
          other.securityStamp == this.securityStamp &&
          other.borderColor == this.borderColor &&
          other.layout == this.layout &&
          other.releasedAt == this.releasedAt);
}

class CardsCompanion extends UpdateCompanion<Card> {
  final Value<String> scryfallId;
  final Value<String> oracleId;
  final Value<String> name;
  final Value<String?> manaCost;
  final Value<double> cmc;
  final Value<String> typeLine;
  final Value<String?> oracleText;
  final Value<String?> colors;
  final Value<String> colorIdentity;
  final Value<String> setCode;
  final Value<String> setName;
  final Value<String> collectorNumber;
  final Value<String> rarity;
  final Value<String> finishes;
  final Value<double?> priceUsd;
  final Value<double?> priceUsdFoil;
  final Value<double?> priceUsdEtched;
  final Value<double?> priceEur;
  final Value<double?> priceEurFoil;
  final Value<String?> imageUriSmall;
  final Value<String?> imageUriNormal;
  final Value<bool> isFullart;
  final Value<bool> isPromo;
  final Value<String?> frameEffects;
  final Value<String?> securityStamp;
  final Value<String?> borderColor;
  final Value<String> layout;
  final Value<String> releasedAt;
  final Value<int> rowid;
  const CardsCompanion({
    this.scryfallId = const Value.absent(),
    this.oracleId = const Value.absent(),
    this.name = const Value.absent(),
    this.manaCost = const Value.absent(),
    this.cmc = const Value.absent(),
    this.typeLine = const Value.absent(),
    this.oracleText = const Value.absent(),
    this.colors = const Value.absent(),
    this.colorIdentity = const Value.absent(),
    this.setCode = const Value.absent(),
    this.setName = const Value.absent(),
    this.collectorNumber = const Value.absent(),
    this.rarity = const Value.absent(),
    this.finishes = const Value.absent(),
    this.priceUsd = const Value.absent(),
    this.priceUsdFoil = const Value.absent(),
    this.priceUsdEtched = const Value.absent(),
    this.priceEur = const Value.absent(),
    this.priceEurFoil = const Value.absent(),
    this.imageUriSmall = const Value.absent(),
    this.imageUriNormal = const Value.absent(),
    this.isFullart = const Value.absent(),
    this.isPromo = const Value.absent(),
    this.frameEffects = const Value.absent(),
    this.securityStamp = const Value.absent(),
    this.borderColor = const Value.absent(),
    this.layout = const Value.absent(),
    this.releasedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CardsCompanion.insert({
    required String scryfallId,
    required String oracleId,
    required String name,
    this.manaCost = const Value.absent(),
    required double cmc,
    required String typeLine,
    this.oracleText = const Value.absent(),
    this.colors = const Value.absent(),
    required String colorIdentity,
    required String setCode,
    required String setName,
    required String collectorNumber,
    required String rarity,
    required String finishes,
    this.priceUsd = const Value.absent(),
    this.priceUsdFoil = const Value.absent(),
    this.priceUsdEtched = const Value.absent(),
    this.priceEur = const Value.absent(),
    this.priceEurFoil = const Value.absent(),
    this.imageUriSmall = const Value.absent(),
    this.imageUriNormal = const Value.absent(),
    this.isFullart = const Value.absent(),
    this.isPromo = const Value.absent(),
    this.frameEffects = const Value.absent(),
    this.securityStamp = const Value.absent(),
    this.borderColor = const Value.absent(),
    required String layout,
    required String releasedAt,
    this.rowid = const Value.absent(),
  }) : scryfallId = Value(scryfallId),
       oracleId = Value(oracleId),
       name = Value(name),
       cmc = Value(cmc),
       typeLine = Value(typeLine),
       colorIdentity = Value(colorIdentity),
       setCode = Value(setCode),
       setName = Value(setName),
       collectorNumber = Value(collectorNumber),
       rarity = Value(rarity),
       finishes = Value(finishes),
       layout = Value(layout),
       releasedAt = Value(releasedAt);
  static Insertable<Card> custom({
    Expression<String>? scryfallId,
    Expression<String>? oracleId,
    Expression<String>? name,
    Expression<String>? manaCost,
    Expression<double>? cmc,
    Expression<String>? typeLine,
    Expression<String>? oracleText,
    Expression<String>? colors,
    Expression<String>? colorIdentity,
    Expression<String>? setCode,
    Expression<String>? setName,
    Expression<String>? collectorNumber,
    Expression<String>? rarity,
    Expression<String>? finishes,
    Expression<double>? priceUsd,
    Expression<double>? priceUsdFoil,
    Expression<double>? priceUsdEtched,
    Expression<double>? priceEur,
    Expression<double>? priceEurFoil,
    Expression<String>? imageUriSmall,
    Expression<String>? imageUriNormal,
    Expression<bool>? isFullart,
    Expression<bool>? isPromo,
    Expression<String>? frameEffects,
    Expression<String>? securityStamp,
    Expression<String>? borderColor,
    Expression<String>? layout,
    Expression<String>? releasedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scryfallId != null) 'scryfall_id': scryfallId,
      if (oracleId != null) 'oracle_id': oracleId,
      if (name != null) 'name': name,
      if (manaCost != null) 'mana_cost': manaCost,
      if (cmc != null) 'cmc': cmc,
      if (typeLine != null) 'type_line': typeLine,
      if (oracleText != null) 'oracle_text': oracleText,
      if (colors != null) 'colors': colors,
      if (colorIdentity != null) 'color_identity': colorIdentity,
      if (setCode != null) 'set_code': setCode,
      if (setName != null) 'set_name': setName,
      if (collectorNumber != null) 'collector_number': collectorNumber,
      if (rarity != null) 'rarity': rarity,
      if (finishes != null) 'finishes': finishes,
      if (priceUsd != null) 'price_usd': priceUsd,
      if (priceUsdFoil != null) 'price_usd_foil': priceUsdFoil,
      if (priceUsdEtched != null) 'price_usd_etched': priceUsdEtched,
      if (priceEur != null) 'price_eur': priceEur,
      if (priceEurFoil != null) 'price_eur_foil': priceEurFoil,
      if (imageUriSmall != null) 'image_uri_small': imageUriSmall,
      if (imageUriNormal != null) 'image_uri_normal': imageUriNormal,
      if (isFullart != null) 'is_fullart': isFullart,
      if (isPromo != null) 'is_promo': isPromo,
      if (frameEffects != null) 'frame_effects': frameEffects,
      if (securityStamp != null) 'security_stamp': securityStamp,
      if (borderColor != null) 'border_color': borderColor,
      if (layout != null) 'layout': layout,
      if (releasedAt != null) 'released_at': releasedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CardsCompanion copyWith({
    Value<String>? scryfallId,
    Value<String>? oracleId,
    Value<String>? name,
    Value<String?>? manaCost,
    Value<double>? cmc,
    Value<String>? typeLine,
    Value<String?>? oracleText,
    Value<String?>? colors,
    Value<String>? colorIdentity,
    Value<String>? setCode,
    Value<String>? setName,
    Value<String>? collectorNumber,
    Value<String>? rarity,
    Value<String>? finishes,
    Value<double?>? priceUsd,
    Value<double?>? priceUsdFoil,
    Value<double?>? priceUsdEtched,
    Value<double?>? priceEur,
    Value<double?>? priceEurFoil,
    Value<String?>? imageUriSmall,
    Value<String?>? imageUriNormal,
    Value<bool>? isFullart,
    Value<bool>? isPromo,
    Value<String?>? frameEffects,
    Value<String?>? securityStamp,
    Value<String?>? borderColor,
    Value<String>? layout,
    Value<String>? releasedAt,
    Value<int>? rowid,
  }) {
    return CardsCompanion(
      scryfallId: scryfallId ?? this.scryfallId,
      oracleId: oracleId ?? this.oracleId,
      name: name ?? this.name,
      manaCost: manaCost ?? this.manaCost,
      cmc: cmc ?? this.cmc,
      typeLine: typeLine ?? this.typeLine,
      oracleText: oracleText ?? this.oracleText,
      colors: colors ?? this.colors,
      colorIdentity: colorIdentity ?? this.colorIdentity,
      setCode: setCode ?? this.setCode,
      setName: setName ?? this.setName,
      collectorNumber: collectorNumber ?? this.collectorNumber,
      rarity: rarity ?? this.rarity,
      finishes: finishes ?? this.finishes,
      priceUsd: priceUsd ?? this.priceUsd,
      priceUsdFoil: priceUsdFoil ?? this.priceUsdFoil,
      priceUsdEtched: priceUsdEtched ?? this.priceUsdEtched,
      priceEur: priceEur ?? this.priceEur,
      priceEurFoil: priceEurFoil ?? this.priceEurFoil,
      imageUriSmall: imageUriSmall ?? this.imageUriSmall,
      imageUriNormal: imageUriNormal ?? this.imageUriNormal,
      isFullart: isFullart ?? this.isFullart,
      isPromo: isPromo ?? this.isPromo,
      frameEffects: frameEffects ?? this.frameEffects,
      securityStamp: securityStamp ?? this.securityStamp,
      borderColor: borderColor ?? this.borderColor,
      layout: layout ?? this.layout,
      releasedAt: releasedAt ?? this.releasedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scryfallId.present) {
      map['scryfall_id'] = Variable<String>(scryfallId.value);
    }
    if (oracleId.present) {
      map['oracle_id'] = Variable<String>(oracleId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (manaCost.present) {
      map['mana_cost'] = Variable<String>(manaCost.value);
    }
    if (cmc.present) {
      map['cmc'] = Variable<double>(cmc.value);
    }
    if (typeLine.present) {
      map['type_line'] = Variable<String>(typeLine.value);
    }
    if (oracleText.present) {
      map['oracle_text'] = Variable<String>(oracleText.value);
    }
    if (colors.present) {
      map['colors'] = Variable<String>(colors.value);
    }
    if (colorIdentity.present) {
      map['color_identity'] = Variable<String>(colorIdentity.value);
    }
    if (setCode.present) {
      map['set_code'] = Variable<String>(setCode.value);
    }
    if (setName.present) {
      map['set_name'] = Variable<String>(setName.value);
    }
    if (collectorNumber.present) {
      map['collector_number'] = Variable<String>(collectorNumber.value);
    }
    if (rarity.present) {
      map['rarity'] = Variable<String>(rarity.value);
    }
    if (finishes.present) {
      map['finishes'] = Variable<String>(finishes.value);
    }
    if (priceUsd.present) {
      map['price_usd'] = Variable<double>(priceUsd.value);
    }
    if (priceUsdFoil.present) {
      map['price_usd_foil'] = Variable<double>(priceUsdFoil.value);
    }
    if (priceUsdEtched.present) {
      map['price_usd_etched'] = Variable<double>(priceUsdEtched.value);
    }
    if (priceEur.present) {
      map['price_eur'] = Variable<double>(priceEur.value);
    }
    if (priceEurFoil.present) {
      map['price_eur_foil'] = Variable<double>(priceEurFoil.value);
    }
    if (imageUriSmall.present) {
      map['image_uri_small'] = Variable<String>(imageUriSmall.value);
    }
    if (imageUriNormal.present) {
      map['image_uri_normal'] = Variable<String>(imageUriNormal.value);
    }
    if (isFullart.present) {
      map['is_fullart'] = Variable<bool>(isFullart.value);
    }
    if (isPromo.present) {
      map['is_promo'] = Variable<bool>(isPromo.value);
    }
    if (frameEffects.present) {
      map['frame_effects'] = Variable<String>(frameEffects.value);
    }
    if (securityStamp.present) {
      map['security_stamp'] = Variable<String>(securityStamp.value);
    }
    if (borderColor.present) {
      map['border_color'] = Variable<String>(borderColor.value);
    }
    if (layout.present) {
      map['layout'] = Variable<String>(layout.value);
    }
    if (releasedAt.present) {
      map['released_at'] = Variable<String>(releasedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('scryfallId: $scryfallId, ')
          ..write('oracleId: $oracleId, ')
          ..write('name: $name, ')
          ..write('manaCost: $manaCost, ')
          ..write('cmc: $cmc, ')
          ..write('typeLine: $typeLine, ')
          ..write('oracleText: $oracleText, ')
          ..write('colors: $colors, ')
          ..write('colorIdentity: $colorIdentity, ')
          ..write('setCode: $setCode, ')
          ..write('setName: $setName, ')
          ..write('collectorNumber: $collectorNumber, ')
          ..write('rarity: $rarity, ')
          ..write('finishes: $finishes, ')
          ..write('priceUsd: $priceUsd, ')
          ..write('priceUsdFoil: $priceUsdFoil, ')
          ..write('priceUsdEtched: $priceUsdEtched, ')
          ..write('priceEur: $priceEur, ')
          ..write('priceEurFoil: $priceEurFoil, ')
          ..write('imageUriSmall: $imageUriSmall, ')
          ..write('imageUriNormal: $imageUriNormal, ')
          ..write('isFullart: $isFullart, ')
          ..write('isPromo: $isPromo, ')
          ..write('frameEffects: $frameEffects, ')
          ..write('securityStamp: $securityStamp, ')
          ..write('borderColor: $borderColor, ')
          ..write('layout: $layout, ')
          ..write('releasedAt: $releasedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CorpusDatabase extends GeneratedDatabase {
  _$CorpusDatabase(QueryExecutor e) : super(e);
  $CorpusDatabaseManager get managers => $CorpusDatabaseManager(this);
  late final $CardsTable cards = $CardsTable(this);
  late final Index idxCardsName = Index(
    'idx_cards_name',
    'CREATE INDEX idx_cards_name ON cards (name)',
  );
  late final Index idxCardsSetCode = Index(
    'idx_cards_set_code',
    'CREATE INDEX idx_cards_set_code ON cards (set_code)',
  );
  late final Index idxCardsTypeLine = Index(
    'idx_cards_type_line',
    'CREATE INDEX idx_cards_type_line ON cards (type_line)',
  );
  late final Index idxCardsColorIdentity = Index(
    'idx_cards_color_identity',
    'CREATE INDEX idx_cards_color_identity ON cards (color_identity)',
  );
  late final Index idxCardsRarity = Index(
    'idx_cards_rarity',
    'CREATE INDEX idx_cards_rarity ON cards (rarity)',
  );
  late final Index idxCardsPriceUsd = Index(
    'idx_cards_price_usd',
    'CREATE INDEX idx_cards_price_usd ON cards (price_usd)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cards,
    idxCardsName,
    idxCardsSetCode,
    idxCardsTypeLine,
    idxCardsColorIdentity,
    idxCardsRarity,
    idxCardsPriceUsd,
  ];
}

typedef $$CardsTableCreateCompanionBuilder =
    CardsCompanion Function({
      required String scryfallId,
      required String oracleId,
      required String name,
      Value<String?> manaCost,
      required double cmc,
      required String typeLine,
      Value<String?> oracleText,
      Value<String?> colors,
      required String colorIdentity,
      required String setCode,
      required String setName,
      required String collectorNumber,
      required String rarity,
      required String finishes,
      Value<double?> priceUsd,
      Value<double?> priceUsdFoil,
      Value<double?> priceUsdEtched,
      Value<double?> priceEur,
      Value<double?> priceEurFoil,
      Value<String?> imageUriSmall,
      Value<String?> imageUriNormal,
      Value<bool> isFullart,
      Value<bool> isPromo,
      Value<String?> frameEffects,
      Value<String?> securityStamp,
      Value<String?> borderColor,
      required String layout,
      required String releasedAt,
      Value<int> rowid,
    });
typedef $$CardsTableUpdateCompanionBuilder =
    CardsCompanion Function({
      Value<String> scryfallId,
      Value<String> oracleId,
      Value<String> name,
      Value<String?> manaCost,
      Value<double> cmc,
      Value<String> typeLine,
      Value<String?> oracleText,
      Value<String?> colors,
      Value<String> colorIdentity,
      Value<String> setCode,
      Value<String> setName,
      Value<String> collectorNumber,
      Value<String> rarity,
      Value<String> finishes,
      Value<double?> priceUsd,
      Value<double?> priceUsdFoil,
      Value<double?> priceUsdEtched,
      Value<double?> priceEur,
      Value<double?> priceEurFoil,
      Value<String?> imageUriSmall,
      Value<String?> imageUriNormal,
      Value<bool> isFullart,
      Value<bool> isPromo,
      Value<String?> frameEffects,
      Value<String?> securityStamp,
      Value<String?> borderColor,
      Value<String> layout,
      Value<String> releasedAt,
      Value<int> rowid,
    });

class $$CardsTableFilterComposer
    extends Composer<_$CorpusDatabase, $CardsTable> {
  $$CardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get scryfallId => $composableBuilder(
    column: $table.scryfallId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oracleId => $composableBuilder(
    column: $table.oracleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get manaCost => $composableBuilder(
    column: $table.manaCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cmc => $composableBuilder(
    column: $table.cmc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get typeLine => $composableBuilder(
    column: $table.typeLine,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oracleText => $composableBuilder(
    column: $table.oracleText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colors => $composableBuilder(
    column: $table.colors,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorIdentity => $composableBuilder(
    column: $table.colorIdentity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setCode => $composableBuilder(
    column: $table.setCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get setName => $composableBuilder(
    column: $table.setName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collectorNumber => $composableBuilder(
    column: $table.collectorNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rarity => $composableBuilder(
    column: $table.rarity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get finishes => $composableBuilder(
    column: $table.finishes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get priceUsd => $composableBuilder(
    column: $table.priceUsd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get priceUsdFoil => $composableBuilder(
    column: $table.priceUsdFoil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get priceUsdEtched => $composableBuilder(
    column: $table.priceUsdEtched,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get priceEur => $composableBuilder(
    column: $table.priceEur,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get priceEurFoil => $composableBuilder(
    column: $table.priceEurFoil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUriSmall => $composableBuilder(
    column: $table.imageUriSmall,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUriNormal => $composableBuilder(
    column: $table.imageUriNormal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFullart => $composableBuilder(
    column: $table.isFullart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPromo => $composableBuilder(
    column: $table.isPromo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frameEffects => $composableBuilder(
    column: $table.frameEffects,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get securityStamp => $composableBuilder(
    column: $table.securityStamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get borderColor => $composableBuilder(
    column: $table.borderColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releasedAt => $composableBuilder(
    column: $table.releasedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CardsTableOrderingComposer
    extends Composer<_$CorpusDatabase, $CardsTable> {
  $$CardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get scryfallId => $composableBuilder(
    column: $table.scryfallId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oracleId => $composableBuilder(
    column: $table.oracleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get manaCost => $composableBuilder(
    column: $table.manaCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cmc => $composableBuilder(
    column: $table.cmc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get typeLine => $composableBuilder(
    column: $table.typeLine,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oracleText => $composableBuilder(
    column: $table.oracleText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colors => $composableBuilder(
    column: $table.colors,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorIdentity => $composableBuilder(
    column: $table.colorIdentity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setCode => $composableBuilder(
    column: $table.setCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setName => $composableBuilder(
    column: $table.setName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectorNumber => $composableBuilder(
    column: $table.collectorNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rarity => $composableBuilder(
    column: $table.rarity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get finishes => $composableBuilder(
    column: $table.finishes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get priceUsd => $composableBuilder(
    column: $table.priceUsd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get priceUsdFoil => $composableBuilder(
    column: $table.priceUsdFoil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get priceUsdEtched => $composableBuilder(
    column: $table.priceUsdEtched,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get priceEur => $composableBuilder(
    column: $table.priceEur,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get priceEurFoil => $composableBuilder(
    column: $table.priceEurFoil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUriSmall => $composableBuilder(
    column: $table.imageUriSmall,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUriNormal => $composableBuilder(
    column: $table.imageUriNormal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFullart => $composableBuilder(
    column: $table.isFullart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPromo => $composableBuilder(
    column: $table.isPromo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frameEffects => $composableBuilder(
    column: $table.frameEffects,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get securityStamp => $composableBuilder(
    column: $table.securityStamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get borderColor => $composableBuilder(
    column: $table.borderColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get layout => $composableBuilder(
    column: $table.layout,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releasedAt => $composableBuilder(
    column: $table.releasedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CardsTableAnnotationComposer
    extends Composer<_$CorpusDatabase, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get scryfallId => $composableBuilder(
    column: $table.scryfallId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get oracleId =>
      $composableBuilder(column: $table.oracleId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get manaCost =>
      $composableBuilder(column: $table.manaCost, builder: (column) => column);

  GeneratedColumn<double> get cmc =>
      $composableBuilder(column: $table.cmc, builder: (column) => column);

  GeneratedColumn<String> get typeLine =>
      $composableBuilder(column: $table.typeLine, builder: (column) => column);

  GeneratedColumn<String> get oracleText => $composableBuilder(
    column: $table.oracleText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colors =>
      $composableBuilder(column: $table.colors, builder: (column) => column);

  GeneratedColumn<String> get colorIdentity => $composableBuilder(
    column: $table.colorIdentity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get setCode =>
      $composableBuilder(column: $table.setCode, builder: (column) => column);

  GeneratedColumn<String> get setName =>
      $composableBuilder(column: $table.setName, builder: (column) => column);

  GeneratedColumn<String> get collectorNumber => $composableBuilder(
    column: $table.collectorNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rarity =>
      $composableBuilder(column: $table.rarity, builder: (column) => column);

  GeneratedColumn<String> get finishes =>
      $composableBuilder(column: $table.finishes, builder: (column) => column);

  GeneratedColumn<double> get priceUsd =>
      $composableBuilder(column: $table.priceUsd, builder: (column) => column);

  GeneratedColumn<double> get priceUsdFoil => $composableBuilder(
    column: $table.priceUsdFoil,
    builder: (column) => column,
  );

  GeneratedColumn<double> get priceUsdEtched => $composableBuilder(
    column: $table.priceUsdEtched,
    builder: (column) => column,
  );

  GeneratedColumn<double> get priceEur =>
      $composableBuilder(column: $table.priceEur, builder: (column) => column);

  GeneratedColumn<double> get priceEurFoil => $composableBuilder(
    column: $table.priceEurFoil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUriSmall => $composableBuilder(
    column: $table.imageUriSmall,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUriNormal => $composableBuilder(
    column: $table.imageUriNormal,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFullart =>
      $composableBuilder(column: $table.isFullart, builder: (column) => column);

  GeneratedColumn<bool> get isPromo =>
      $composableBuilder(column: $table.isPromo, builder: (column) => column);

  GeneratedColumn<String> get frameEffects => $composableBuilder(
    column: $table.frameEffects,
    builder: (column) => column,
  );

  GeneratedColumn<String> get securityStamp => $composableBuilder(
    column: $table.securityStamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get borderColor => $composableBuilder(
    column: $table.borderColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get layout =>
      $composableBuilder(column: $table.layout, builder: (column) => column);

  GeneratedColumn<String> get releasedAt => $composableBuilder(
    column: $table.releasedAt,
    builder: (column) => column,
  );
}

class $$CardsTableTableManager
    extends
        RootTableManager<
          _$CorpusDatabase,
          $CardsTable,
          Card,
          $$CardsTableFilterComposer,
          $$CardsTableOrderingComposer,
          $$CardsTableAnnotationComposer,
          $$CardsTableCreateCompanionBuilder,
          $$CardsTableUpdateCompanionBuilder,
          (Card, BaseReferences<_$CorpusDatabase, $CardsTable, Card>),
          Card,
          PrefetchHooks Function()
        > {
  $$CardsTableTableManager(_$CorpusDatabase db, $CardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> scryfallId = const Value.absent(),
                Value<String> oracleId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> manaCost = const Value.absent(),
                Value<double> cmc = const Value.absent(),
                Value<String> typeLine = const Value.absent(),
                Value<String?> oracleText = const Value.absent(),
                Value<String?> colors = const Value.absent(),
                Value<String> colorIdentity = const Value.absent(),
                Value<String> setCode = const Value.absent(),
                Value<String> setName = const Value.absent(),
                Value<String> collectorNumber = const Value.absent(),
                Value<String> rarity = const Value.absent(),
                Value<String> finishes = const Value.absent(),
                Value<double?> priceUsd = const Value.absent(),
                Value<double?> priceUsdFoil = const Value.absent(),
                Value<double?> priceUsdEtched = const Value.absent(),
                Value<double?> priceEur = const Value.absent(),
                Value<double?> priceEurFoil = const Value.absent(),
                Value<String?> imageUriSmall = const Value.absent(),
                Value<String?> imageUriNormal = const Value.absent(),
                Value<bool> isFullart = const Value.absent(),
                Value<bool> isPromo = const Value.absent(),
                Value<String?> frameEffects = const Value.absent(),
                Value<String?> securityStamp = const Value.absent(),
                Value<String?> borderColor = const Value.absent(),
                Value<String> layout = const Value.absent(),
                Value<String> releasedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion(
                scryfallId: scryfallId,
                oracleId: oracleId,
                name: name,
                manaCost: manaCost,
                cmc: cmc,
                typeLine: typeLine,
                oracleText: oracleText,
                colors: colors,
                colorIdentity: colorIdentity,
                setCode: setCode,
                setName: setName,
                collectorNumber: collectorNumber,
                rarity: rarity,
                finishes: finishes,
                priceUsd: priceUsd,
                priceUsdFoil: priceUsdFoil,
                priceUsdEtched: priceUsdEtched,
                priceEur: priceEur,
                priceEurFoil: priceEurFoil,
                imageUriSmall: imageUriSmall,
                imageUriNormal: imageUriNormal,
                isFullart: isFullart,
                isPromo: isPromo,
                frameEffects: frameEffects,
                securityStamp: securityStamp,
                borderColor: borderColor,
                layout: layout,
                releasedAt: releasedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scryfallId,
                required String oracleId,
                required String name,
                Value<String?> manaCost = const Value.absent(),
                required double cmc,
                required String typeLine,
                Value<String?> oracleText = const Value.absent(),
                Value<String?> colors = const Value.absent(),
                required String colorIdentity,
                required String setCode,
                required String setName,
                required String collectorNumber,
                required String rarity,
                required String finishes,
                Value<double?> priceUsd = const Value.absent(),
                Value<double?> priceUsdFoil = const Value.absent(),
                Value<double?> priceUsdEtched = const Value.absent(),
                Value<double?> priceEur = const Value.absent(),
                Value<double?> priceEurFoil = const Value.absent(),
                Value<String?> imageUriSmall = const Value.absent(),
                Value<String?> imageUriNormal = const Value.absent(),
                Value<bool> isFullart = const Value.absent(),
                Value<bool> isPromo = const Value.absent(),
                Value<String?> frameEffects = const Value.absent(),
                Value<String?> securityStamp = const Value.absent(),
                Value<String?> borderColor = const Value.absent(),
                required String layout,
                required String releasedAt,
                Value<int> rowid = const Value.absent(),
              }) => CardsCompanion.insert(
                scryfallId: scryfallId,
                oracleId: oracleId,
                name: name,
                manaCost: manaCost,
                cmc: cmc,
                typeLine: typeLine,
                oracleText: oracleText,
                colors: colors,
                colorIdentity: colorIdentity,
                setCode: setCode,
                setName: setName,
                collectorNumber: collectorNumber,
                rarity: rarity,
                finishes: finishes,
                priceUsd: priceUsd,
                priceUsdFoil: priceUsdFoil,
                priceUsdEtched: priceUsdEtched,
                priceEur: priceEur,
                priceEurFoil: priceEurFoil,
                imageUriSmall: imageUriSmall,
                imageUriNormal: imageUriNormal,
                isFullart: isFullart,
                isPromo: isPromo,
                frameEffects: frameEffects,
                securityStamp: securityStamp,
                borderColor: borderColor,
                layout: layout,
                releasedAt: releasedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CardsTableProcessedTableManager =
    ProcessedTableManager<
      _$CorpusDatabase,
      $CardsTable,
      Card,
      $$CardsTableFilterComposer,
      $$CardsTableOrderingComposer,
      $$CardsTableAnnotationComposer,
      $$CardsTableCreateCompanionBuilder,
      $$CardsTableUpdateCompanionBuilder,
      (Card, BaseReferences<_$CorpusDatabase, $CardsTable, Card>),
      Card,
      PrefetchHooks Function()
    >;

class $CorpusDatabaseManager {
  final _$CorpusDatabase _db;
  $CorpusDatabaseManager(this._db);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
}
