#!/bin/bash

# generateConfig.sh [old config] [new config] -
#     makes a configuration using an old one as a template

if [[ $# -ne 2 ]]; then
    >&2 echo "Usage: $0 <old config> <new config>"
    exit 1
fi

OLD_NAME=$1
NEW_NAME=$2

OLD_PATH=${SUSHYFT_BASE}/config/$1
NEW_PATH=${SUSHYFT_BASE}/config/$2

if [[ ! -d $OLD_PATH ]]; then
    >&2 echo "ERROR: Can't find old config $OLD_NAME"
    exit 1
fi

if [[ -e $NEW_PATH ]]; then
    >&2 echo "ERROR: Target config already exists"
    exit 1
fi

# check the new one doesn't match anybody
MISMATCH_COUNT=$(ls -d ${SUSHYFT_BASE}/config/* | grep ${2}_ | wc -l)
if [[ $MISMATCH_COUNT -ne 0 ]]; then
    >&2 echo "ERROR: Target name is too close to existing name(s)"
    >&2 ls -d ${NEW_PATH}_
    exit 1
fi

# check anybody doesn't match us
for DIR in $(ls -d ${SUSHYFT_BASE}/config/* | xargs -n 1 basename); do
    if [[ ${2} == ${DIR}_* ]]; then
        >&2 echo "ERROR: Target name is too close to existing name ${DIR}"
        exit 1
    fi
done

>&/dev/null pushd $SUSHYFT_BASE
GIT_OUTPUT=$(git diff --shortstat 2>/dev/null | tail -n1)

if [[ $GIT_OUTPUT != "" ]]; then
    >&2 echo "You need to have a clean git index to generate a config,"
    >&2 echo "please commit or stash your current index before continuing"
    >&2 git status
    >/dev/null popd
    exit 1
fi
>&/dev/null popd

cp -a ${OLD_PATH} ${NEW_PATH}
find ${NEW_PATH} -type f | xargs -n1 perl -pi -e "s,${OLD_NAME},${NEW_NAME},g"

GREP_OUTPUT1=$(grep -R ${OLD_NAME} ${NEW_PATH} 2>&1)
GREP_OUTPUT2=$(grep -R ${OLD_NAME} ${NEW_PATH} 2>/dev/null | sed "s/${NEW_NAME}//g" | grep ${OLD_NAME})
GREP_STATUS=$?


if [ $GREP_STATUS -eq 0 ]; then
    >&2 echo "Failed to properly fix this file, manually touch it up:"
    >&2 echo "$GREP_OUTPUT1"
    >&2 echo " (please ensure that no instances of ${OLD_NAME} exist"
fi

>&/dev/null pushd ${SUSHYFT_BASE}
git add ${NEW_PATH} 1>&/dev/null
git commit -e -F- <<EOF
Autogenerating new config
Created '${NEW_NAME}' from '${OLD_NAME}'
EOF
>&/dev/null popd


