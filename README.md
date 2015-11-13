 The aim of this class is to take a number of ordered enumerators and then
 emit their values in ascending order.

 Some assumptions:
   * The enumerators passed in emit their values in ascending order.
   * The enumerators emit values which are comparable with each other.
   * The enumerators can be finite *or* infinite.

You can run the test suite with: `ruby combined_enumerator.rb`.
