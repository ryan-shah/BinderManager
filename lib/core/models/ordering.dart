/// Shared ordering vocabulary for search results and binder organization.
///
/// Kept in core/models so the drift table definitions, the query engine,
/// the allocator, and the UI dropdowns all agree on one set of axes (D6).
library;

/// Direction for any sort axis.
enum SortDirection { asc, desc }

/// The group-by / sort-by axes a binder offers (D6).
///
/// Group and sort are two independent axes sharing this list: e.g. *group
/// by* [cardType], *sort by* [price] desc. Persisted by name via
/// `textEnum` — renaming a value is a data migration.
enum BinderAxis {
  cardType,
  color,
  setCode,
  rarity,
  price,
  name,
  finish;

  /// Human label for dropdowns.
  String get label => switch (this) {
        BinderAxis.cardType => 'Card type',
        BinderAxis.color => 'Color',
        BinderAxis.setCode => 'Set',
        BinderAxis.rarity => 'Rarity',
        BinderAxis.price => 'Price',
        BinderAxis.name => 'Name',
        BinderAxis.finish => 'Finish',
      };
}
