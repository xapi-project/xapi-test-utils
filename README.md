[![Build Status](https://travis-ci.org/xapi-project/xapi-test-utils.svg?branch=master)](https://travis-ci.org/xapi-project/xapi-test-utils)

This framework should be useful if you want to apply lots of different
inputs to a function or system, and check that the output is correct in
each case.

The basic idea is to either:

1. Create a module of type `STATELESS_TEST` or
2. Create a module of type `STATEFUL_TEST`

Passing this the the appropriate `Make` functor will yield a module which can be run with alcotest. See `xen-api` for examples.
