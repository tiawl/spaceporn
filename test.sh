#!/bin/sh

rm -f zig-cache/o/*/test
zig build test
zig-cache/o/*/test
