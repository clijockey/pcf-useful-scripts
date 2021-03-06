#!/usr/bin/env bash
#==============================================================================
# Title:                
# Description:          
#                       
#                       
# Author:          		Rob Edwards (@clijockey)
# Date:                 
# Version:              0.1
# Notes:                
#                       
# Limitations/issues:
#==============================================================================

# use set -e instead of #!/bin/bash -e in case we're
# called with `bash ~/bin/scriptname`
set -e # bail out early if any command fails
set -u # fail if we hit unset variables
set -o pipefail # fail if any component of any pipe fails

# Set some output colours for feedback during setup
info () {
    printf " [ \033[00;34m..\033[0m ] $1\n"
}

user () {
    printf "\r [ \033[0;33m?\033[0m ] $1 "
}

success () {
    printf "\r\033[2K [ \033[00;32mAPP\033[0m ] $1\n"
}

fail () {
    printf "\r\033[2K [\033[0;31mFAIL\033[0m] $1 \n"
    echo ''
    exit
}
error_exit() {
	echo "${1:-"Unknown Error"}" 1>&2
	exit 1
}

bold=$(tput bold)
normal=$(tput sgr0)

main() {
    check_dependancies
    # Work out the current org and space logged into
    org=$(jq -r -c ".OrganizationFields.Name" ~/.cf/config.json || error_exit "Looks like you might not be logged into the CF CLI")
    space=$(jq -r -c ".SpaceFields.Name" ~/.cf/config.json || error_exit "Looks like you might not be logged into the CF CLI")
    
    echo "Parsing to understand which Diego cell the application insatnces are running on in the org ${org} and space ${space};"

    space_guid=$(cf space ${space} --guid || error_exit "Looks like you might not be logged into the CF CLI")

    app_guids=$(cf curl /v2/spaces/${space_guid}/apps | jq -r -c '.resources[].metadata.guid')
    for app_guid in ${app_guids} 
    do
        app_stats=$(cf curl /v2/apps/${app_guid}/stats)
        
        route=$(echo $app_stats | jq -c -r '.[].stats.uris' | sort -u)
        hosts=$(echo $app_stats | jq -c -r '.[].stats.host')
        name=$(echo $app_stats | jq -c -r '.[].stats.name' | sort -u)
    
        cells=$(echo ${hosts} | tr " " "\n")

        success "Application called ${bold}${name}${normal} ${route} is deployed on the following cells"
        
        for x in ${cells}
        do
            info "${x}"
        done
        echo ""
    done
}

check_dependancies() {
    if [[ "$(which jq)X" == "X" ]]
    then
        echo "Please install jq"
        exit 1
    fi
   
    if [[ "$(which cf)X" == "X" ]]
    then
        echo "Please install cf"
        exit 1
    fi
    
}

main "$@"