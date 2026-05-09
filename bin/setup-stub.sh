#!/bin/bash


export REPO=/opt/repo
export BRANCH="$(cd ${REPO} && git branch -r --contains HEAD | sed 's^.*origin/^^')"
export GIT_REMOTE="https://github.com/bnext-bio/nucleus-jupyterhub.git"
export LOG_FILE=/home/${NB_USER}/.log/`date -Iseconds`-setup.log

echo "In setup-stub: logging to $LOG_FILE"
mkdir -p `dirname $LOG_FILE` && chown $NB_USER `dirname $LOG_FILE`
touch $LOG_FILE && chown $NB_USER $LOG_FILE

# If we're running as root, we're in an environment that is expecting us to transition
# into a specific user.
if [ "$(id -u)" == 0 ]; then
    # Ensure our user is added to the users group within the container so we can write in /opt
    gpasswd -a $NB_USER users
fi

# Permissions on repository might be weird if we're running as a local user
# 

sudo --preserve-env --set-home --user "${NB_USER}" bash <<'EOF'
git config --global --add safe.directory ${REPO} 

echo "Updating git repository: ${REPO} on ${BRANCH}" | tee -a ${LOG_FILE}
if [ ! -d ${REPO} ]; then
    git clone --depth=1 ${GIT_REMOTE} ${REPO} |& tee -a ${LOG_FILE}
fi

cd ${REPO}
git status |& tee -a ${LOG_FILE}
git remote set-url origin ${GIT_REMOTE} |& tee -a ${LOG_FILE} # Fix up remote if image was built from a repo with an SSH origin.

if [ -n "${BRANCH}" ]; then
    git checkout ${BRANCH} |& tee -a ${LOG_FILE}
    git pull |& tee -a ${LOG_FILE}
fi
EOF

# echo "Fixing up permissions: new user $NB_USER" | tee -a ${LOG_FILE}
# chown -R ${NB_USER} /opt/repo /opt/noderoots /opt/conda |& tee -a ${LOG_FILE}

echo "Running main setup" | tee -a ${LOG_FILE}
sudo --preserve-env --set-home --user "${NB_USER}" "/opt/repo/bin/setup.sh" |& tee -a ${LOG_FILE}