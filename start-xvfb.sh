#!/bin/bash
# setup xvfb for headless mode without xServer present on linux
# https://github.com/openscad/openscad/issues/1798
Xvfb :99 &
