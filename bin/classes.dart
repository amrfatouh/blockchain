import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

extension ConvertHexaToBinary on String {
  String toBin() {
    String output = '';
    split('').forEach((letter) {
      output += int.parse(letter, radix: 16).toRadixString(2).padLeft(4, '0');
    });
    return output;
  }
}

int findNonce(Block block) {
  block.blockHeader.nonce = 0;
  String computedHash = block.computeHash();
  String binaryHash = computedHash.toBin();
  while (!binaryHash.startsWith('0' * block.blockHeader.difficulty!)) {
    block.blockHeader.nonce += 1;
    computedHash = block.computeHash();
    binaryHash = computedHash.toBin();
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
  int blockCount = 0;
  bool? constantDifficulty;
  int? constDiffValue;
  Blockchain() {
    print('Would you like difficulty to be constant? (y/n)');
    constantDifficulty = stdin.readLineSync() == 'y';

    if (constantDifficulty!) {
      print('Enter the value of constant difficulty:');
      constDiffValue = int.parse((stdin.readLineSync() ?? '4'));
    }
    print('Enter number of legit blocks before starting attack:');
    int? countBeforeAttack = int.parse((stdin.readLineSync() ?? '10'));
    print(
        'Enter the number z, where z is how many blocks behind the last block from which the attack will start:');
    int? z = int.parse((stdin.readLineSync() ?? '3'));

    if (countBeforeAttack <= z) {
      print(
          'error: number of legit blocks before attack can\'t be less than or equal to z');
      return;
    }

    print('Enter the computational power of the attacker (1 - 100):');
    int? compPower = int.parse((stdin.readLineSync() ?? '60'));

    print('Enter the computational power of the honest node A:');
    int? compPowerForNodeA = int.parse((stdin.readLineSync() ?? '20'));
    print('Enter the computational power of the honest node B:');
    int? compPowerForNodeB = int.parse((stdin.readLineSync() ?? '10'));
    print('Enter the computational power of the honest node C:');
    int? compPowerForNodeC = int.parse((stdin.readLineSync() ?? '10'));

    print('Input Data');
    print('=' * 'Input Data'.length);
    print('use constant difficulty: $constantDifficulty');
    if (constantDifficulty!) {
      print('constant difficulty value: $constDiffValue');
    }
    print('number of legit blocks before starting attack: $countBeforeAttack');
    print('value of z: $z');
    print('attacker computational power: $compPower%');

    Block? honestLastBlock;
    Block? attackerLastBlock;
    DateTime? attackBeginingTime;

    generateGenesisBlock();
    honestLastBlock = genesisBlock!;
    while (blockCount < countBeforeAttack) {
      Block newBlock = mineNewBlock(honestLastBlock!);
      honestLastBlock.appendAt(honestLastBlock, newBlock);
      honestLastBlock = newBlock;
    }
    genesisBlock!.traverseDepthFirst((block) {
      if (block.blockHeight == countBeforeAttack - 1 - z) {
        attackerLastBlock = block;
      }
    });
    attackBeginingTime = DateTime.now();
    Block attackerNewBlock = configureNewBlock(attackerLastBlock!);
    Block honestNewBlockA = configureNewBlock(honestLastBlock!);
    Block honestNewBlockB = configureNewBlock(honestLastBlock);
    Block honestNewBlockC = configureNewBlock(honestLastBlock);
    bool honestNodeSolvesPuzzle = false;
    while (attackerLastBlock!.blockHeight! <= honestLastBlock!.blockHeight!) {
      //attacker's turn in the round robin
      attackerNewBlock.blockHeader.nonce =
          resumeNonceMining(attackerNewBlock, compPower);
      if (isValidNonce(attackerNewBlock)) {
        attackerNewBlock.hash = attackerNewBlock.computeHash();
        attackerNewBlock.blockHeight = attackerLastBlock!.blockHeight! + 1;
        blockCount++;
        print('ATTACKER BLOCK');
        attackerLastBlock!.appendAt(attackerLastBlock, attackerNewBlock);
        attackerLastBlock = attackerNewBlock;
        print(attackerLastBlock);
        attackerNewBlock = configureNewBlock(attackerLastBlock!);
      }

      //honest node A tun in round robin
      if (!honestNodeSolvesPuzzle) {
        honestNewBlockA.blockHeader.nonce =
            resumeNonceMining(honestNewBlockA, compPowerForNodeA);
        if (isValidNonce(honestNewBlockA)) {
          honestNewBlockA.hash = honestNewBlockA.computeHash();
          honestNewBlockA.blockHeight = honestLastBlock.blockHeight! + 1;
          blockCount++;
          print('NODE A BLOCK');
          honestLastBlock.appendAt(honestLastBlock, honestNewBlockA);
          honestLastBlock = honestNewBlockA;
          print(honestLastBlock);
          honestNodeSolvesPuzzle = true;
        }
      }

        //honest node B tun in round robin
      if (!honestNodeSolvesPuzzle) {
        honestNewBlockB.blockHeader.nonce =
            resumeNonceMining(honestNewBlockB, compPowerForNodeB);
        if (isValidNonce(honestNewBlockB)) {
          honestNewBlockB.hash = honestNewBlockB.computeHash();
          honestNewBlockB.blockHeight = honestLastBlock.blockHeight! + 1;
          blockCount++;
          print('NODE B BLOCK');
          honestLastBlock.appendAt(honestLastBlock, honestNewBlockB);
          honestLastBlock = honestNewBlockB;
          print(honestLastBlock);
          honestNodeSolvesPuzzle = true;
        }
      }

          //honest node C tun in round robin
      if (!honestNodeSolvesPuzzle) {
        honestNewBlockC.blockHeader.nonce =
            resumeNonceMining(honestNewBlockC, compPowerForNodeC);
        if (isValidNonce(honestNewBlockC)) {
          honestNewBlockC.hash = honestNewBlockC.computeHash();
          honestNewBlockC.blockHeight = honestLastBlock.blockHeight! + 1;
          blockCount++;
          print('NODE C BLOCK');
          honestLastBlock.appendAt(honestLastBlock, honestNewBlockC);
          honestLastBlock = honestNewBlockC;
          print(honestLastBlock);
          honestNodeSolvesPuzzle = true;
        }
      }

      //configuring honest block node
      if (honestNodeSolvesPuzzle) {
        honestNewBlockA = configureNewBlock(honestLastBlock);
        honestNewBlockB = configureNewBlock(honestLastBlock);
        honestNewBlockC = configureNewBlock(honestLastBlock);
        honestNodeSolvesPuzzle = false;
      }
    }

    // while (attackerLastBlock!.blockHeight! <= honestLastBlock!.blockHeight!) {
    //     // int num = Random().nextInt(99) + 1;
    //     if (num <= compPower) {
    //       print('ATTACKER BLOCK');
    //       Block attackerNewBlock = mineNewBlock(attackerLastBlock!);
    //       attackerLastBlock!.appendAt(attackerLastBlock, attackerNewBlock);
    //       attackerLastBlock = attackerNewBlock;
    //     } else {
    //       Block honestNewBlock = mineNewBlock(honestLastBlock);
    //       honestLastBlock.appendAt(honestLastBlock, honestNewBlock);
    //       honestLastBlock = honestNewBlock;
    //     }
    //   }
    DateTime attackEndingTime = DateTime.now();
    Duration attackElapsedTime =
        attackEndingTime.difference(attackBeginingTime);

    print('');
    print('Attack Results');
    print('=' * 'Attack Results'.length);
    print('Z: $z');
    print('elapsed attack time: $attackElapsedTime');
    print('attacker speed: $compPower%');
    print('legit blockchain speed: ${100 - compPower}%');
    print('count of legit blocks: ${honestLastBlock.blockHeight! + 1} blocks');
    print(
        'count of fraudulent blocks: ${attackerLastBlock!.blockHeight! - (countBeforeAttack - z - 1)} blocks');
    print('');

    // genesisBlock!.traverseDepthFirst((node) => print(node));
    // print('----------');
    // print(attackerLastBlock);
    // print(honestLastBlock);

    // while (true) {
    // for (int i = 0; i < 10; i++) {
    //   Block lastBlock = getLastBlock();
    //   Block newBlock = mineNewBlock(lastBlock);

    //   //adding the new block to the blockchain
    //   lastBlock.appendAt(lastBlock, newBlock);
    // }

    // }
  }
  Block configureNewBlock(Block lastBlock) {
    Block newBlock = Block(
      blockHeader: BlockHeader(
        previousHash: lastBlock.hash!,
        timestamp: DateTime.now(),
      ),
    );
    if (constantDifficulty!) {
      newBlock.blockHeader.difficulty = constDiffValue;
    } else {
      int newDifficulty = difficultyRetargetting(lastBlock, newBlock);
      newBlock.blockHeader.difficulty = newDifficulty;
    }
    newBlock.blockHeader.nonce = 0;
    //you must set the block height before appending it
    return newBlock;
  }

  int resumeNonceMining(Block block, int trialsCount) {
    int n = 0;
    String computedHash = block.computeHash();
    String binaryHash = computedHash.toBin();
    while ((!binaryHash.startsWith('0' * block.blockHeader.difficulty!)) &&
        (n < trialsCount)) {
      block.blockHeader.nonce += 1;
      computedHash = block.computeHash();
      binaryHash = computedHash.toBin();
      n++;
    }
    return block.blockHeader.nonce;
  }

  bool isValidNonce(Block block) {
    String computedHash = block.computeHash();
    String binaryHash = computedHash.toBin();
    if (binaryHash.startsWith('0' * block.blockHeader.difficulty!)) {
      return true;
    } else {
      return false;
    }
  }

  Block mineNewBlock(Block lastBlock) {
    Block newBlock = Block(
      blockHeader: BlockHeader(
        previousHash: lastBlock.hash!,
        timestamp: DateTime.now(),
      ),
    );
    if (constantDifficulty!) {
      newBlock.blockHeader.difficulty = constDiffValue;
    } else {
      int newDifficulty = difficultyRetargetting(lastBlock, newBlock);
      newBlock.blockHeader.difficulty = newDifficulty;
    }
    newBlock.blockHeader.nonce = findNonce(newBlock);
    newBlock.hash = newBlock.computeHash();
    newBlock.blockHeight = lastBlock.blockHeight! + 1;

    blockCount++;
    print(newBlock);
    return newBlock;
  }

  Block getLastBlock() {
    genesisBlock!.getLevels();
    Block lastBlock = (genesisBlock!.getLastNodes()
          ..sort((Block a, Block b) =>
              (a).blockHeader.timestamp.compareTo((b).blockHeader.timestamp)))
        .last;
    return lastBlock;
  }

  int difficultyRetargetting(Block lastBlock, Block newBlock) {
    int newDifficulty = lastBlock.blockHeader.difficulty!;
    int secondsPassed = DateTime.now()
        .difference(genesisBlock!.blockHeader.timestamp)
        .inSeconds;

    if (blockCount > secondsPassed) {
      newDifficulty++;
    } else if (blockCount < secondsPassed && newDifficulty - 1 > 0) {
      newDifficulty--;
    }

    // Duration difference = newBlock.blockHeader.timestamp
    //     .difference(lastBlock.blockHeader.timestamp);
    // Duration minRateDuration = Duration(seconds: minRate);
    // // if difference between new timestamp and last timestamp is less than minRate
    // if (difference.compareTo(minRateDuration) < 0) {
    //   newDifficulty += 1;
    // } else if (lastBlock.blockHeader.difficulty! - 1 > 0) {
    //   // newDifficulty -= 1;
    //   newDifficulty =
    //       ((newDifficulty / difference.inSeconds.toInt()).ceil()).toInt();
    // }
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
    genesisBlock!.blockHeader.difficulty = 16;
    genesisBlock!.transactionsList.clear();
    genesisBlock!.blockHeader.nonce = findNonce(genesisBlock!);
    genesisBlock!.hash = genesisBlock!.computeHash();
    blockCount++;
    print(genesisBlock);
  }

  @override
  String toString() {
    return genesisBlock.toString();
  }
}
