#!/bin/bash

assert_equal() {
  if [[ "$1" != "$2" ]]; then
    echo "actual: $1"
    echo "expected: $2"
    return 1
  fi
}

assert_success() {
  if [[ "$status" != 0 ]]; then
    echo "expected: 0"
    echo "actual: $status"
    echo "output: $output"
    return 1
  fi
}
