#!/bin/sh
set -e

xctool -workspace ShiftScheduler -scheme ShiftScheduler build test

