/// The finish of a physical card.
enum Finish {
  nonfoil,
  foil,
  etched;

  /// Parses a finish from a Scryfall string (e.g. "nonfoil", "foil", "etched").
  /// Returns null if unrecognised.
  static Finish? tryParse(String value) {
    switch (value) {
      case 'nonfoil':
        return Finish.nonfoil;
      case 'foil':
        return Finish.foil;
      case 'etched':
        return Finish.etched;
      default:
        return null;
    }
  }
}

/// Uniquely identifies a single physical card by its Scryfall ID and finish.
///
/// Two copies of the same printing in different finishes (e.g. foil vs
/// non-foil) are distinct [CardIdentity] values.
class CardIdentity {
  const CardIdentity(this.scryfallId, this.finish);

  /// The Scryfall UUID for this printing.
  final String scryfallId;

  /// The physical finish of this copy.
  final Finish finish;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardIdentity &&
          runtimeType == other.runtimeType &&
          scryfallId == other.scryfallId &&
          finish == other.finish;

  @override
  int get hashCode => Object.hash(scryfallId, finish);

  @override
  String toString() => 'CardIdentity($scryfallId, ${finish.name})';
}
