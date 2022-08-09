#!/bin/sh

# Red Hat OpenJdk Interns command line tool - for use in "lazy" development

# REQUIRES:
# github CLI tool
# easy install: $ sudo dnf install gh

set -e

cli_name=${0##*/}
cli_name=${cli_name%.*}

help_message="
$cli_name CLI - Red Hat OpenJdk Interns command line tool - for use in \"lazy\" development    

usage: $cli_name [--version] <command> [<args>] 

Some commands have additional arguments. For example, the 'gh' command has a 'syncall' subcommand.
Use '$cli_name help <command>' or '$cli_name commands --verbose' for details on subcommands."

commands="
general commands
    help        Show this help message
    commands    List all commands and their usage 
    version     Show the version of this CLI

workflow commands
    gh/git      Apply various lazy Git commands"

##############################################################################################
# Lazy General commands                                                                                    
##############################################################################################

cli_help () {
    echo "$help_message"
    echo "$commands"
    exit 1
}

##############################################################################################
# Lazy Git commands
##############################################################################################
# REQUIRES:
# github CLI tool
# easy install: $ sudo dnf install gh
##############################################################################################

cli_git_help () {
    echo "
    gh/git      Apply various lazy Git commands  

    syncall     Synchronize a branch of a remote fork with the main branch of the source repository
    "
    exit 1
}

# Use this in each repository, to sync your forked repo's main branch with its source repo on GitHub.
#
# (if no arguments are given, then uses the current directory name as your remote fork name and uses GH_USER)
# export GH_USER=maxcao13 # change this to your username
# Example: lazyintern.sh syncall, lazyintern.sh syncall cryostat-knowledge-hub, lazyintern.sh syncall cryostat-knowledge-hub maxcao13 -f -b main 
cli_git_syncall () {
    pull() {
        git checkout $branch_name
        git fetch origin
        git fetch upstream
        git pull
    }
    # Error messaging setup
    usage="Usage: cli_name git syncall [<remote-fork-name>] [<github-username>] [options]"
    options_list="
-f force sync
-b <branch> sync to a specific branch
-h show this help message"
    args=0

    # Variable setup
    branch_name="main"

    # Parse arguments
    while true; do
        # Options
        while getopts "b:fhn" o; do
            case ${o} in
                b) # name of the branch to sync to
                    branch_name=$OPTARG
                    ;;    
                f) # force sync
                    echo "(with force)"
                    lz_gh_sync_f="--force"
                    ;;
                h) # show help message
                    echo "$usage"
                    echo "$options_list"
                    exit 0
                    ;;
                n) # dont update local repo
                    echo "(with no pull)"
                    lz_gh_sync_n="--no-pull"
                    ;;
                *)
                    exit 1
                    ;;
            esac
        done
 
        while [[ $OPTIND -le $# && ${!OPTIND} != -* ]]; do
            if [[ args -eq 0 ]]; then
                repo_name=${!OPTIND}
                args=$((args+1))
            elif [[ args -eq 1 ]]; then
                GH_USER=${!OPTIND}
                args=$((args+1))
            else 
                echo "Invalid argumemt: ${!OPTIND}"
                echo "$usage" 
                echo "$options_list "
                exit 1
            fi

            ((OPTIND++))
        done
        # Stop when we've run out of arguments
        if [[ $OPTIND > $# ]]; then
            break
        fi
    done

    # Argument validation
    if [ -z "$repo_name" ]; then
        repo_name=$(basename $(pwd))
    fi

    if [ -z $GH_USER ]; then
        echo "You must set the GH_USER environment variable to your GitHub username or provide a second argument as your username"
        exit 1
    fi

    # do the command
    echo "Syncing ${GH_USER}/${repo_name}#$branch_name with GitHub..."
    echo $lz_gh_sync_f
    echo $branch_name
    gh repo sync $GH_USER/$repo_name -b $branch_name $lz_gh_sync_f

    # check if no pull
    if [ -z $lz_gh_sync_n ]; then
        pull
    fi

    exit 1
}


##############################################################################################
# Main
##############################################################################################

case "$1" in
  gh|git)
    case "$2" in
        syncall)
            cli_git_syncall ${@:3}
            ;;
        *)
            cli_git_help
            ;;
    esac
    ;;
  *)
    cli_help
    ;;
esac

# e.g. usage
# $ gh syncall
# $ gh syncall maxcao13
# $ gh syncall maxcao13 cryostat
