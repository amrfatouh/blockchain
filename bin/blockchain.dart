import 'dart:io';

import 'classes.dart';

void main(List<String> arguments) {
  Blockchain();
  print('restart again? (y/n)');
  while (stdin.readLineSync() == 'y') {
    Blockchain();
    print('restart again? (y/n)');
  }
}

// DateTime t1 = DateTime.now();
// Blockchain blockchain = Blockchain();
// DateTime t2 = DateTime.now();
// print(blockchain);
// print(t2.difference(t1));