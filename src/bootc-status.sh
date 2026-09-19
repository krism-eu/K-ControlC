#!/bin/sh
case "$1" in
  json) exec /usr/bin/bootc status --format json --format-version=1 ;;
  humanreadable) exec /usr/bin/bootc status --format humanreadable ;;
  *) exit 2 ;;
esac
