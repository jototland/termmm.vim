#! /bin/bash

token=_vim_is_finished_
file=

realpath() {
    echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

function waitFinished() {
    local result
    while true; do
        trap ' ' INT
        result=$(read -s result; printf '%s\n' "$result")
        if [[ $? != 0 ]]; then
            printf '\e]51;["call","Tapi_toggleterm_cancel_wait","'"$file"'"]\a'
            echo -n ^C
            exit 1
        fi
        trap - INT
        if [[ "$result" = "$token" ]]; then
            exit 0
        fi
    done
}

function open() {
    if [[ -n $NVIM_LISTEN_ADDRESS ]]; then
        nvr -cc split --remote "$file"
    else
        printf '\e]51;["drop",'"$file"']\a'
    fi
}

function openWait() {
    if [[ -n $NVIM_LISTEN_ADDRESS ]]; then
        nvr -cc split --remote-wait "$file"
    else
        printf '\e]51;["call","Tapi_toggleterm_open_wait",["'"$file"'","'"$token"'"]]\a'
        waitFinished
    fi
}

function usage() {
    echo "                   sendbacktovim.sh"
    echo "                   =============.sh"
    echo ""
    echo "Send files to vim from vims builtin terminal"
    echo ""
    echo "Usage:"
    echo ""
    echo "sendbacktovim edit <filename>"
    echo "  - opens <filename> in vim, and waits for edit to finish"
    echo "sendbacktovim drop <filename>"
    echo "  - opens <filenam> in vim, exits immediately"
}

if [[ "$#" != 2 ]]; then
    usage
    exit 1
fi

file=$(realpath "$2")
case "$1" in
    edit) openWait ;;
    drop) open ;;
    *)
        usage
        exit 1
        ;;
esac
