#!/bin/bash

error() {
    echo
    echo -e "\033[0;31m${1}\033[0m"

    exit 1
}

if [ -f ./.build/versions.env ]; then
    # xargs does not support the -d option on BSD (MacOS X)
    export $(grep -a -v -e '^#' -e '^[[:space:]]*$' .build/versions.env | tr '\n' '\0' | xargs -0 )
    grep -a -v -e '^#' -e '^[[:space:]]*$' .build/versions.env | tr '\n' '\0' | xargs -0 printf "\$%s\n"
    echo
fi



if node --version >/dev/null; then
    echo Found node.js $(node --version)
else
    error "Could not find node.js"
fi
if git --version >/dev/null; then
    echo Found $(git --version)
else
    error "Could not find Git"
fi



case "$-" in
    *i*) _wget_interactive_options="--show-progress" ;;
      *) _wget_interactive_options= ;;
esac

if [ ! -d .tmp ]; then mkdir .tmp; fi



if [ -f ./.env ]; then
    # xargs does not support the -d option on BSD (MacOS X)
    export $(grep -a -v -e '^#' -e '^[[:space:]]*$' .env | tr '\n' '\0' | xargs -0)
    grep -a -v -e '^#' -e '^[[:space:]]*$' .env | tr '\n' '\0' | xargs -0 printf "\$%s\n"
    echo
fi
