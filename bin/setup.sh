#!/bin/bash

HOME=/home/jovyan
GIT_REMOTE="https://github.com/bnext-bio/nucleus-jupyterhub.git"
REPO=/opt/repo
JUPYTER_SETTINGS=/opt/conda/share/jupyter/lab/settings
DEVNOTE_PATH=/home/jovyan/work/devnotes/template

echo "Setting up environment"

# Bring down and update our baseline home directory
if [ ! -d ${REPO} ]; then
    git clone --depth=1 https://github.com/bnext-bio/jupyterhub-deploy-docker.git ${REPO} &>/dev/null
fi
git pull ${REPO}

rsync -av ${REPO}/home-overlay/ ${HOME}

# Update our jupyter configuration
cat ${REPO}/envs/jupyter_server_config_additional.py >> ${HOME}/.jupyter/jupyter_server_config.py
mkdir -p ${JUPYTER_SETTINGS}
cp ${REPO}/envs/overrides.json ${JUPYTER_SETTINGS}/overrides.json

# Install our key packages
~/.local/bin/uv pip install --system -e ${REPO}/envs/nucleus-env

# Bring down the curvenote template
# if [ -d ${DEVNOTE_PATH} ]; then 
#     cd ${DEVNOTE_PATH}
#     git pull --ff-only 
# else
#     git clone --depth=1 https://github.com/antonrmolina/devnote-template.git ${DEVNOTE_PATH}
# fi

# Create LSP symlink
ln -s / ${HOME}/work/.lsp_symlink