import 'package:binder_manager/core/models/binder_diff.dart';
import 'package:binder_manager/shared/providers/binder_providers.dart';

/// Records [stage] calls; overrides [binderChangeStagerProvider] in widget
/// tests so change events don't hit real databases.
class FakeBinderChangeStager implements BinderChangeStager {
  final List<ChangeTrigger> triggers = [];

  @override
  Future<void> stage(ChangeTrigger trigger) async {
    triggers.add(trigger);
  }
}
