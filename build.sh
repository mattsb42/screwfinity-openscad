#!/bin/bash
rm -f build/vectors/*
pytest -v $@
