#!/bin/bash
rm -f build/vectors/*

if [[ $GITHUB_ACTIONS ]];then
    # setup xvfb for headless mode without xServer present on linux
    # https://github.com/openscad/openscad/issues/1798
    Xvfb :99 & export DISPLAY=:99
fi

pipenv run pytest -v $@
