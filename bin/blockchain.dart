import 'classes.dart';

void main(List<String> arguments) {
  DateTime t1 = DateTime.now();
  Blockchain();
  DateTime t2 = DateTime.now();
  print(t2.difference(t1));
}

// DateTime t1 = DateTime.now();
// Blockchain blockchain = Blockchain();
// DateTime t2 = DateTime.now();
// print(blockchain);
// print(t2.difference(t1));