import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:lakbay_core/lakbay_core.dart';

/// Supplies the bundled seed data, decoded and keyed by collection name.
abstract interface class SeedSource {
  Future<Map<String, Object?>> load();
}

/// Reads `assets/data/<collection>.json`.
class AssetSeedSource implements SeedSource {
  const AssetSeedSource([this.bundle]);

  final AssetBundle? bundle;

  @override
  Future<Map<String, Object?>> load() async {
    final assets = bundle ?? rootBundle;
    return {
      for (final name in TravelData.collections)
        name: jsonDecode(await assets.loadString('assets/data/$name.json')),
    };
  }
}
