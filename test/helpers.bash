#!/bin/bash

assert_equal() {
  if [[ "$1" != "$2" ]]; then
    echo "actual: $1"
    echo "expected: $2"
    return 1
  fi
}
