#!/bin/sh
case "$1" in
  json|humanreadable) exec /usr/bin/bootc status --format "$1" ;;
  *) exit 2 ;;
esac
