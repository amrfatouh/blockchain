import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'tree.dart';

class Block {
  String? hash;
  int? blockHeight;
  BlockHeader blockHeader;
  List<Transaction> transactionsList;

  Block({
    required this.blockHeader,
  }) : transactionsList =
            List.generate(3, (i) => Transaction.randomTransaction()) {}

  String computeHash() {
    String concatenatedBlockHeader = blockHeader.previousHash +
        blockHeader.nonce.toString() +
        blockHeader.difficulty.toString() +
        blockHeader.timestamp.toString();

    var bytes = utf8.encode(concatenatedBlockHeader);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // factory Block.generateGenesisBlock() {
  //   int diffculty = 2;
  //   int nonce = findNonce(this);
  //   return Block(
  //     blockHeader: BlockHeader(
  //         difficulty: 2, previousHash: previousHash, timestamp: timestamp),
  //     blockHeight: 0,
  //     hash: "0" /* TODO: to be done */,
  //     transactionsList: [],
  //   );
  // }

  @override
  String toString() {
    return {
      'hash': hash,
      'blockHeight': blockHeight,
      'transactionList': transactionsList,
      'blockHeader': blockHeader,
    }.toString();
  }
}

String proofOfWork(Block block) {
  block.blockHeader.nonce = 0;
  String computedHash = block.computeHash();
  while (!computedHash.startsWith('0' * block.blockHeader.difficulty!)) {
    block.blockHeader.nonce += 1;
    computedHash = block.computeHash();
  }
  return computedHash;
}

int findNonce(Block block) {
  block.blockHeader.nonce = 0;
  String computedHash = block.computeHash();
  while (!computedHash.startsWith('0' * block.blockHeader.difficulty!)) {
    block.blockHeader.nonce += 1;
    computedHash = block.computeHash();
  }
  return block.blockHeader.nonce;
}

class BlockHeader {
  DateTime timestamp;
  String previousHash;
  int nonce = 0;
  int? difficulty;

  BlockHeader({
    required this.previousHash,
    required this.timestamp,
  });

  @override
  String toString() {
    return {
      'timestamp': timestamp,
      'previousHash': previousHash,
      'nonce': nonce,
      'difficulty': difficulty,
    }.toString();
  }
}

class Transaction {
  String sender;
  String receiver;
  int value;

  Transaction(this.receiver, this.sender, this.value);

  factory Transaction.randomTransaction() {
    List<String> names = [
      'Ahmed',
      'Mohamed',
      'Amr',
      'Ziad',
      'Fady',
      'Omar',
      'Hany',
      'Malak'
    ];
    String randomReceiver = names[Random().nextInt(7)];
    String randomSender = names[Random().nextInt(7)];
    return Transaction(randomReceiver, randomSender, Random().nextInt(100));
  }

  @override
  String toString() {
    return {
      'sender': sender,
      'receiver': receiver,
      'value': value,
    }.toString();
  }
}

const minRate = 1;

class Blockchain {
  TreeNode? root;
  Block? genesisBlock;

  Blockchain() {
    generateGenesisBlock();
    root = TreeNode(genesisBlock!);
    // while (true) {
    for (int i = 0; i < 10; i++) {
      root!.getLevels();
      TreeNode lastBlockTreeNode = (root!.getLastNodes()
            ..sort((TreeNode a, TreeNode b) => (a.block)
                .blockHeader
                .timestamp
                .compareTo((b.block).blockHeader.timestamp)))
          .last;
      Block lastBlock = lastBlockTreeNode.block;
      Block newBlock = Block(
        blockHeader: BlockHeader(
          previousHash: lastBlock.hash!,
          timestamp: DateTime.now(),
        ),
      );

      int newDifficulty = lastBlock.blockHeader.difficulty!;

      Duration difference = newBlock.blockHeader.timestamp
          .difference(lastBlock.blockHeader.timestamp);
      Duration minRateDuration = Duration(seconds: minRate);
      if (difference.compareTo(minRateDuration) < 0) {
        newDifficulty += 1;
      } else if (lastBlock.blockHeader.difficulty! - 1 > 0) {
        newDifficulty -= 1;
      }
      newBlock.blockHeader.difficulty = newDifficulty;
      newBlock.blockHeader.nonce = findNonce(newBlock);
      newBlock.hash = proofOfWork(newBlock);

      TreeNode newBlockTreeNode = TreeNode(newBlock);

      lastBlockTreeNode.appendAt(lastBlockTreeNode, newBlockTreeNode);
      root!.getLevels();
      int blockHeight = newBlockTreeNode.getHeight();
      newBlock.blockHeight = blockHeight;
    }

    root!.traverseDepthFirst((node) => print(node.block));

    // }
  }

  //TODO: void difficultyRetargetting(Block lastBlock, Block newBlock) {}

  void generateGenesisBlock() {
    genesisBlock = Block(
      blockHeader: BlockHeader(
        previousHash: '0',
        timestamp: DateTime.now(),
      ),
    );
    genesisBlock!.blockHeight = 0;
    genesisBlock!.blockHeader.difficulty = 2;
    genesisBlock!.transactionsList.clear();
    genesisBlock!.blockHeader.nonce = findNonce(genesisBlock!);
    genesisBlock!.hash = genesisBlock!.computeHash();
  }

  @override
  String toString() {
    return genesisBlock.toString();
  }
}
