// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/nullability/nullability_node.dart';

/// Data structure to keep track of the relationship between [NullabilityNode]
/// objects.
class NullabilityGraph {
  /// Map from a nullability node to those nodes that are "downstream" from it
  /// (meaning that if a key node is nullable, then all the nodes in the
  /// corresponding value will either have to be nullable, or null checks will
  /// have to be added).
  final _downstream = Map<NullabilityNode, List<NullabilityNode>>.identity();

  /// Map from a nullability node to those nodes that are "upstream" from it
  /// (meaning that if a node in the value is nullable, then the corresponding
  /// key node will have to be nullable, or null checks will have to be added).
  final _upstream = Map<NullabilityNode, List<NullabilityNode>>.identity();

  /// Records that [sourceNode] is immediately upstream from [destinationNode].
  void connect(NullabilityNode sourceNode, NullabilityNode destinationNode) {
    (_downstream[sourceNode] ??= []).add(destinationNode);
    (_upstream[destinationNode] ??= []).add(sourceNode);
  }

  /// Iterates through all nodes that are "downstream" of [node] (i.e. if
  /// [node] is nullable, then all the iterated nodes will either have to be
  /// nullable, or null checks will have to be added).
  ///
  /// There is no guarantee of uniqueness of the iterated nodes.
  Iterable<NullabilityNode> getDownstreamNodes(NullabilityNode node) =>
      _downstream[node] ?? const [];

  /// Iterates through all nodes that are "upstream" of [node] (i.e. if
  /// any of the iterated nodes are nullable, then [node] will either have to be
  /// nullable, or null checks will have to be added).
  //  ///
  //  /// There is no guarantee of uniqueness of the iterated nodes.
  Iterable<NullabilityNode> getUpstreamNodes(NullabilityNode node) =>
      _upstream[node] ?? const [];
}
