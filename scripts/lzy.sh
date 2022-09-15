#!/bin/sh

# Red Hat OpenJdk Interns command line tool - for use in "lazy" development

# curl this with curl `https://raw.githubusercontent.com/rhat-openjdk-interns/cryostat-knowledge-hub/main/scripts/lzy.sh > lzy.sh`

CLI_NAME=${0##*/}
CLI_NAME=${CLI_NAME%.*}

# Add yourself to this if contributed
CLI_VERSION="v1.0.0"
CLI_CONTR="Developed by: 
\tMax Cao (@maxcao13)\n\tThuan Vo (@tthvo)"

# REQUIRES:
# git
# gh (github CLI tool)
DEPS="gh git"

# API call to gh server
if [ -z "$LZ_GH_USER" ]; then
    export LZ_GH_USER=$(gh api user --jq '.login')
fi

gh_help_message="gh/git      Apply various lazy Git commands"

help_message="
$CLI_NAME CLI - Red Hat OpenJdk Interns command line tool - for use in \"lazy\" development    

usage: $CLI_NAME <command> [<args>] 

Some commands have additional arguments. 
e.g., the 'gh' command has a 'syncall' subcommand.

Use '$CLI_NAME <command> -h'for more details on subcommands."

commands="
general commands
    help        Show this help message
    commands    List all commands and their usage 
    version     Show the version of this CLI

workflow commands
    $gh_help_message
    "

##############################################################################################
# Setup Helper Functions
##############################################################################################

# Check if dependencies are installed
checkDependencies() {
    local pm=""
    for p in $*;do
        ! command -v $p > /dev/null 2>&1 && pm="$p $pm"
    done
    if [[ "$pm" != "" ]]; then
        echo "Error: Following packages needs to be installed!!"
        for p in $pm;do
            echo -e "\t$p"
        done
        exit 1
    fi
}

# Ensure that the user is logged in to GitHub through the gh CLI tool
# (TODO): Eventually we should probably 'cache' credentials, so that we don't run api calls all the time but probably when this is not a sh script anymore
ensureLoggedIn() {
  ! gh auth status &> /dev/null && echo "Not logged in. Running git auth login..." && ! gh auth login && exit 1
}

##############################################################################################
# Lazy General commands                                                                                    
##############################################################################################

cli_help () {
    echo "$help_message"
    echo "$commands"
    exit 0
}

##############################################################################################
# Lazy Git commands
##############################################################################################
# REQUIRES:
# github CLI tool
# easy install: $ sudo dnf install gh 
# then ensure you are logged in: $ gh auth login
##############################################################################################

cli_git_help () {
    echo "
    $gh_help_message

    syncall     Synchronize a branch of a remote fork with the main branch of the source repository
                lzy aliases - [s] 
    "
    exit 0
}

# Use this in each repository, to sync your forked repo's main branch with its source repo on GitHub.
#
# Optional arguemnts are used: 
#   $1 - is the remote fork name, $2 is the remote GitHub username
#   (if no arguments are given, then uses the current directory name as your remote fork name and uses your gh CLI login as the remote user)

# Example: lzy.sh gh s, lzy.sh git syncall cryostat-knowledge-hub, lzy.sh syncall cryostat-knowledge-hub maxcao13 -f -b main 
cli_git_syncall () {
    pull() {
        git checkout $branch_name
        git fetch origin
        git fetch upstream
        git pull
    }
    # Error messaging setup
    usage="Usage: CLI_NAME git syncall [<remote-fork-name>] [<github-username>] [options]"
    options_list="
-b <branch> sync to a specific branch
-f force sync
-h show this help message
-n don't pull into local repository, only sync fork"

    # Helper for parsing arguments
    args=0

    # Variable setup
    branch_name="main"

    # Parse arguments
    while true; do
        # Options
        while getopts "b:fhn" opt; do
            case ${opt} in
                b) # name of the branch to sync to
                    branch_name=$OPTARG
                    ;;    
                f) # force sync
                    lz_gh_sync_f="--force"
                    ;;
                h) # show help message
                    echo "$usage"
                    echo "$options_list"
                    exit 0
                    ;;
                n) # dont update local repo
                    lz_gh_sync_n="--no-pull"
                    ;;
                *)
                    exit 1
                    ;;
            esac
        done
 
        while [[ $OPTIND -le $# && ${!OPTIND} != -* ]]; do
            if [[ $args -eq 0 ]]; then
                repo_name=${!OPTIND}
                args=$((args+1))
            elif [[ $args -eq 1 ]]; then
                LZ_GH_USER=${!OPTIND}
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

    if [ -z $LZ_GH_USER ]; then
        echo "Auth Error: You must either: 
        1) Login to gh using `gh auth login`
        2) set the LZ_GH_USER environment variable to your GitHub username
        3) provide a second argument as your username"
        exit 1
    fi

    # do the command
    echo "Syncing ${LZ_GH_USER}/${repo_name}#$branch_name with GitHub..."
    gh repo sync $LZ_GH_USER/$repo_name -b $branch_name $lz_gh_sync_f

    # check if no pull
    if [ -z $lz_gh_sync_n ]; then
        pull
    fi

    exit 0
}

##############################################################################################
# Lazy Cryostat commands
##############################################################################################
# REQUIRES:
# cryostat components
##############################################################################################

# Use this to start smoketest.sh in one terminal, and -web in another
# Assumes cryostat and cryostat-web are in ~/workspace

# Example: lzy.sh cr
cry_smoketest_web() {
    gnome-terminal --tab --title="cryostat-web" --command="bash -c 'cd ~/workspace/cryostat-web; echo \"waiting for cryostat to start...\"; sleep 7; yarn start:dev;$SHELL'" & 
    cd ~/workspace/cryostat && CRYOSTAT_DISABLE_SSL=true CRYOSTAT_CORS_ORIGIN=http://localhost:9000 sh ~/workspace/cryostat/smoketest.sh
    exit 0
}

##############################################################################################
# Main
##############################################################################################

checkDependencies $DEPS

case "$1" in
    version)
        echo -e "\n$CLI_NAME $CLI_VERSION\n\n$CLI_CONTR"
    ;;
    gh|git)
        ensureLoggedIn
        case "$2" in
            s|syncall)
                cli_git_syncall ${@:3}
            ;;
            *)
                cli_git_help
            ;;
        esac
    ;;
    cr)
        cry_smoketest_web
    ;;
    *)
        cli_help
    ;;
esac

exit 0

