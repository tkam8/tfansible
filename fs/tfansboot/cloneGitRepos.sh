#!/bin/bash

CWD=`pwd`

cd /home/tfansible
mkdir -p /home/tfansible/log

if [ ! -d "/tmp/tfansible-repo" ]; then
	echo "[cloneGitRepos] Retrieving repository list from ${TFANSIBLE_REPO}#${TFANSIBLE_GH_BRANCH}"
	git clone -b $TFANSIBLE_GH_BRANCH $TFANSIBLE_REPO /tmp/tfansible-repo >> /home/tfansible/log/cloneGitRepos.log 2>&1
fi

# the updateRepos script takes in a json file as an argument, and will automatically look for a user-defined /tmp/user_repos.json 
python /snopsboot/updateRepos.py /tmp/tfansible-repo/images/base/fs/etc/tfansiblerepo.d/base.json
python /tfansboot/cloneGitRepos.py
