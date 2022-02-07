import 'dart:collection';

import 'classes.dart';

class TreeNode {
  Block block;
  TreeNode(this.block);
  List<TreeNode> children = [];
  static Map<TreeNode, int> levels = Map();

  void add(TreeNode child) {
    children.add(child);
  }

  TreeNode? getNode(String hash) {
    if (block.hash == hash) return this;

    for (final child in children) {
      if (child.getNode(hash) != null) return child.getNode(hash);
    }
    return null;
  }

  void getLevels({int level = 0}) {
    levels[this] = level++;
    for (final child in children) {
      child.getLevels(level: level);
    }
  }

  int getHeight() {
    return levels[this] as int;
  }

  List<TreeNode> getLastNodes() {
    int maxLevel = -1;
    levels.forEach((key, value) {
      if (value > maxLevel) maxLevel = value;
    });

    List<TreeNode> lastNodes = [];
    levels.forEach((key, value) {
      if (value == maxLevel) lastNodes.add(key);
    });
    return lastNodes;
  }

  void appendAt(TreeNode? targetNode, TreeNode newNode) {
    targetNode?.children.add(newNode);
  }

  int countNodes() {
    int n = 0;
    if (children.isEmpty) {
      return 1;
    } else {
      for (final child in children) {
        n += child.countNodes();
      }
    }
    return n + 1;
  }

  void traverseDepthFirst(void Function(TreeNode node) performAction) {
    performAction(this);
    for (final child in children) {
      child.traverseDepthFirst(performAction);
    }
  }
}
