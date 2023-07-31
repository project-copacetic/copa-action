#!/bin/bash

assert_equal() {
  if [[ "$1" != "$2" ]]; then
    echo "expected: $1"
    echo "actual: $2"
    return 1
  fi
}
