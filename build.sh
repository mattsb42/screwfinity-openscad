#!/bin/bash
rm -f build/vectors/*
pipenv run pytest -v $@
