#!/bin/bash

# Print a fancy warning message
function warn {
    echo -e '\x1b[0;33mWARN:' $@ '\x1b[0;0m' 1>&2
}

function check_exit {
    if [[ $? != 0 ]]; then
        $1; exit 1
    fi
}


#
# The actual script starts here
#
URL=`git config --get remote.origin.url`
KEEP='public'
RELEASE='release'

TMP_RELEASE='tmp-release'

branch=`git rev-parse --abbrev-ref HEAD`
stamp=`date`

success=false


function cleanup {
    if [ "$success" = "false" ]; then
        echo "Ctrl-C: attempting to revert"
    else
        echo 'Restoring branch'
    fi

    git checkout $branch
    check_exit "echo 'Failed to revert, check your branch and clean-up manually'"
    
    git branch -D $TMP_RELEASE

    exit 1
}
trap cleanup SIGHUP SIGINT SIGTERM EXIT



# Warn the user if there are un-pushed changes
unpushed=`git log @{upstream}..`
if [[ -n $unpushed ]]; then
    warn "You have unpushed changes. Stash or reset them"
    exit 1;
fi

git checkout -b $TMP_RELEASE
check_exit "echo 'can\'t switch to temporary release branch'"


# Build
echo "Building"
npm install
check_exit "echo 'npm install failed'"
npm install grunt-cli
check_exit "echo 'can\'t install grunt commandline'; exit 1"
./node_modules/grunt-cli/bin/grunt build
check_exit "echo 'grunt build failed'"

# Commit
echo "Releasing"
git add -f public
git commit -m "Releasing ${stamp}"
git push -f origin $TMP_RELEASE:$RELEASE

# The exit script will run here
success=true
