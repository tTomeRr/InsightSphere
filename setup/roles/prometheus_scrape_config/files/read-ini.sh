#!/bin/bash
#This script will extract values from an ini config file.
# arg1 is config.ini file
# arg2 is the section (defined with [])

function parse_ini() {
    cat /dev/stdin | awk -v section="$1" '
    BEGIN {
    if (length(section) > 0) { params=1 }
    else { params=0 }
    found=0
    }
    match($0,/;/) { next }
    match($0,/#/) { next }
    match($0,/^\[(.+)\]$/){
    current=substr($0, RSTART+1, RLENGTH-2)
    found=current==section
    next
    }
    match($0,/(.+)/) {
    if (found && length($1)>0) { print $1 }
    }'
}

if [[ -z $2 ]]
then
        echo "ERROR: Required parameters not passed"
        echo "Syntax: read-ini [arg1] [arg2]"
        echo "Arguments:"
        echo -e '\t arg1 = config.ini file'
        echo -e '\t arg2 = section (defined in ini file with [])'
        exit 1
else
        parse_ini $2 < $1
fi

