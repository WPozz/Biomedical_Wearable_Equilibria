import 'dart:math';

// Give a number n for all non negative integers i < n, and print i^4
void smain(n){
  var n = 4;
  for (var i = 0; i < n; i++){
    print(pow(i, 4));}
}

// n the main function, given an integer number n, instantiate a list of n random integers, with possible maximum 
//value 10. Then, for each element of the list, print it multiplied by 2.

void drain() {
  var rng = Random();
  for (var n = 0; n < 5; n++) {
    print(rng.nextInt(10));
  }
}
