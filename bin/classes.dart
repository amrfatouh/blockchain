import 'dart:convert';
import 'dart:math';


import 'package:crypto/crypto.dart';



class Block {
  String? hash;
  int? blockHeight;
  BlockHeader blockHeader;
  List<Transaction> transactionsList;
  List<Block> children = [];
  static Map<Block, int> levels = {};

  Block({
    required this.blockHeader,
  }) : transactionsList =
            List.generate(3, (i) => Transaction.randomTransaction());

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

    void add(Block child) {
    children.add(child);
  }

  Block? getNode(String hash) {
    if (this.hash == hash) return this;

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

  List<Block> getLastNodes() {
    int maxLevel = -1;
    levels.forEach((key, value) {
      if (value > maxLevel) maxLevel = value;
    });

    List<Block> lastNodes = [];
    levels.forEach((key, value) {
      if (value == maxLevel) lastNodes.add(key);
    });
    return lastNodes;
  }

  void appendAt(Block? targetNode, Block newNode) {
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

  void traverseDepthFirst(void Function(Block node) performAction) {
    performAction(this);
    for (final child in children) {
      child.traverseDepthFirst(performAction);
    }
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
  //this is the root block
  Block? genesisBlock;

  Blockchain() {
    generateGenesisBlock();
    // while (true) {
    for (int i = 0; i < 10; i++) {   
      Block lastBlock = getLastBlock();
      Block newBlock = mineNewBlock(lastBlock);
      
      //adding the new block to the blockchain
      lastBlock.appendAt(lastBlock, newBlock);
      
    }

    genesisBlock!.traverseDepthFirst((node) => print(node));

    // }
  }

  Block mineNewBlock(Block lastBlock) {
    Block newBlock = Block(
      blockHeader: BlockHeader(
        previousHash: lastBlock.hash!,
        timestamp: DateTime.now(),
      ),
    );
    int newDifficulty = difficultyRetargetting(lastBlock, newBlock);
    newBlock.blockHeader.difficulty = newDifficulty;
    //newBlock.blockHeader.difficulty = 4;
    newBlock.blockHeader.nonce = findNonce(newBlock);
    newBlock.hash = newBlock.computeHash();
    newBlock.blockHeight = lastBlock.blockHeight! + 1;
    return newBlock;
  }

  Block getLastBlock() {
    genesisBlock!.getLevels();
    Block lastBlock = (genesisBlock!.getLastNodes()
          ..sort((Block a, Block b) => (a)
              .blockHeader
              .timestamp
              .compareTo((b).blockHeader.timestamp)))
        .last;
    return lastBlock;
  }

  int difficultyRetargetting(Block lastBlock, Block newBlock) {
    int newDifficulty = lastBlock.blockHeader.difficulty!;
    
    Duration difference = newBlock.blockHeader.timestamp
        .difference(lastBlock.blockHeader.timestamp);
    Duration minRateDuration = Duration(seconds: minRate);
    if (difference.compareTo(minRateDuration) < 0) {
      newDifficulty += 1;
    } else if (lastBlock.blockHeader.difficulty! - 1 > 0) {
      //newDifficulty -= 1;
      newDifficulty =((newDifficulty / difference.inSeconds.toInt()).ceil()).toInt();
    }
    return newDifficulty;
  }


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
