
let alcotestable_of_pp pp =
  Alcotest.testable (Fmt.of_to_string pp) (=)
