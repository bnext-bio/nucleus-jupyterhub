#!/bin/bash

HOME=/home/jovyan
GIT_REMOTE="https://github.com/bnext-bio/nucleus-jupyterhub.git"
REPO=/opt/repo
JUPYTER_SETTINGS=/opt/conda/share/jupyter/lab/settings
DEVNOTE_PATH=/home/jovyan/work/devnotes/template

echo "Setting up environment"
echo "Running as: `whoami`"
echo "NB_USER: $NB_USER"
echo "NB_UID: $NB_UID"
echo "NB_GID: $NB_GID"
echo "NB_UMASK: $NB_UMASK"
echo "UV_INDEX: $UV_INDEX"

# Bring down and update our baseline home directory
if [ ! -d ${REPO} ]; then
    git clone --depth=1 ${GIT_REMOTE} ${REPO}
fi
cd ${REPO}
git remote set-url origin ${GIT_REMOTE} # Fix up remote if image was built from a repo with an SSH origin.
git pull

rsync -a ${REPO}/home-overlay/ ${HOME}

# Update our jupyter configuration
cat ${REPO}/config/jupyter_server_config_additional.py >> ${HOME}/.jupyter/jupyter_server_config.py
mkdir -p ${JUPYTER_SETTINGS}
cp ${REPO}/config/overrides.json ${JUPYTER_SETTINGS}/overrides.json

# Drop in launcher configuration for the collaboration groups we're a part of
for group in `curl -H "Authorization: token $JUPYTERHUB_API_TOKEN" $JUPYTERHUB_API_URL/user | jq '.groups | join(" ")'`; do
    echo """
- title: ${group}
  description: Open the real-time collaboration server for ${group}
  source: /hub/spawn/${group}-collab
  type: url
  catalog: Collaboration
  args:
      createNewWindow: true
""" > ~/share/jupyter/jupyter_app_launcher/jp_app_launcher_collab_${group}.yml
done

# Install our key packages
~/.local/bin/uv pip install --system -e ${REPO}/nucleus-env --no-progress -v

# Bring down the curvenote template
if [ -d ${DEVNOTE_PATH} ]; then 
    cd ${DEVNOTE_PATH}
    if [ -d .git.disable ]; then
        mv .git.disable .git
        git pull --ff-only
    fi
else
    git clone --depth=1 https://github.com/antonrmolina/devnote-template.git ${DEVNOTE_PATH}
fi
mv ${DEVNOTE_PATH}/.git ${DEVNOTE_PATH}/.git.disable # Un-repoify it so it can be copied and modified easily.

# Create LSP symlink
echo Creating symlink
if [ ! -L ${HOME}/work/.lsp_symlink ]; then
    ln -s / ${HOME}/work/.lsp_symlink
fi

# Create curvenote symlink
echo Linking curvenote config
if [ ! -L ${HOME}/.curvenote ]; then
    ln -s ~/work/.curvenote ~/.curvenote
fi

# Run final shared setup commands
echo Running final setup
if [ -f ${HOME}/work/shared/.setup/setup.sh ]; then
    ${HOME}/work/shared/.setup/setup.sh
fi

echo Nucleus environment setup