#!/bin/bash
DIR="${1}"

cd "${DIR}"
ls | while read packageDir; do
    zip -r "${packageDir}.zip" "${packageDir}"
done
