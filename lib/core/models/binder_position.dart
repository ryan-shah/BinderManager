/// The physical coordinate model for binder pockets (D9).
///
/// Committed cards are tracked at exact (page, side, pocket) coordinates so
/// D7 diffs can emit physically-followable instructions ("Move Ragavan →
/// page 3, back, pocket 5"). Shared by the allocator (position assignment)
/// and the commit engine (location instructions).
library;

/// Which side of a sheet a pocket is on.
///
/// Fill order is front before back (D9), so [front] sorts first.
enum PageSide {
  front,
  back;

  String get label => switch (this) {
        PageSide.front => 'front',
        PageSide.back => 'back',
      };
}

/// One pocket location: 1-based page, side, 1-based pocket within the side.
///
/// Ordering follows the D9 fill order: page-by-page, front side then back
/// side of each sheet, pockets in reading order within a side.
class BinderPosition implements Comparable<BinderPosition> {
  const BinderPosition({
    required this.page,
    required this.side,
    required this.pocket,
  })  : assert(page >= 1, 'pages are 1-based'),
        assert(pocket >= 1, 'pockets are 1-based');

  /// 1-based sheet number.
  final int page;

  final PageSide side;

  /// 1-based pocket within the side, in reading order (left-to-right,
  /// top-to-bottom).
  final int pocket;

  @override
  int compareTo(BinderPosition other) {
    final byPage = page.compareTo(other.page);
    if (byPage != 0) return byPage;
    final bySide = side.index.compareTo(other.side.index);
    if (bySide != 0) return bySide;
    return pocket.compareTo(other.pocket);
  }

  /// Human location instruction fragment, e.g. `page 3, back, pocket 5`.
  String describe() => 'page $page, ${side.label}, pocket $pocket';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BinderPosition &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          side == other.side &&
          pocket == other.pocket;

  @override
  int get hashCode => Object.hash(page, side, pocket);

  @override
  String toString() => 'BinderPosition(${describe()})';
}

/// The pocket layout of a binder: rows×cols per side, page count,
/// single/double-sided (D9). Capacity and ordinal↔position math live here
/// so the allocator and the commit engine can never disagree about where
/// "the next open pocket" is.
class BinderGeometry {
  const BinderGeometry({
    required this.rows,
    required this.cols,
    required this.pageCount,
    required this.doubleSided,
  })  : assert(rows >= 1),
        assert(cols >= 1),
        assert(pageCount >= 0);

  final int rows;
  final int cols;

  /// Number of sheets. A double-sided sheet holds pockets on both sides.
  final int pageCount;

  final bool doubleSided;

  int get pocketsPerSide => rows * cols;

  int get sidesPerPage => doubleSided ? 2 : 1;

  /// Total pockets: pockets/side × sides/page × pages.
  int get capacity => pocketsPerSide * sidesPerPage * pageCount;

  /// The position of the pocket at [ordinal] (0-based) in D9 fill order.
  ///
  /// Throws a [RangeError] when [ordinal] is outside `0..capacity-1`.
  BinderPosition positionAt(int ordinal) {
    RangeError.checkValueInInterval(ordinal, 0, capacity - 1, 'ordinal');
    final perPage = pocketsPerSide * sidesPerPage;
    final page = ordinal ~/ perPage;
    final withinPage = ordinal % perPage;
    final sideIndex = withinPage ~/ pocketsPerSide;
    final pocket = withinPage % pocketsPerSide;
    return BinderPosition(
      page: page + 1,
      side: sideIndex == 0 ? PageSide.front : PageSide.back,
      pocket: pocket + 1,
    );
  }

  /// The 0-based fill-order ordinal of [position].
  ///
  /// Throws an [ArgumentError] when the position does not exist in this
  /// geometry (page/pocket out of range, or a back side on a single-sided
  /// binder).
  int ordinalOf(BinderPosition position) {
    if (!contains(position)) {
      throw ArgumentError.value(position, 'position', 'not in this geometry');
    }
    final perPage = pocketsPerSide * sidesPerPage;
    final sideIndex = position.side == PageSide.front ? 0 : 1;
    return (position.page - 1) * perPage +
        sideIndex * pocketsPerSide +
        (position.pocket - 1);
  }

  /// Whether [position] denotes a real pocket in this geometry.
  bool contains(BinderPosition position) {
    if (position.page < 1 || position.page > pageCount) return false;
    if (position.pocket < 1 || position.pocket > pocketsPerSide) return false;
    if (!doubleSided && position.side == PageSide.back) return false;
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BinderGeometry &&
          runtimeType == other.runtimeType &&
          rows == other.rows &&
          cols == other.cols &&
          pageCount == other.pageCount &&
          doubleSided == other.doubleSided;

  @override
  int get hashCode => Object.hash(rows, cols, pageCount, doubleSided);

  @override
  String toString() =>
      'BinderGeometry(${rows}x$cols, $pageCount pages, '
      '${doubleSided ? 'double' : 'single'}-sided)';
}
