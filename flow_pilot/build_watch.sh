#!/bin/bash
dart run build_runner clean

while true; do
  clear
  dart run build_runner watch -d
done
