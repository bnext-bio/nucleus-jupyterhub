#!/bin/bash

HOME=/home/jovyan
GIT_REMOTE="https://github.com/bnext-bio/nucleus-jupyterhub.git"
REPO=/opt/repo
JUPYTER_SETTINGS=/opt/conda/share/jupyter/lab/settings
DEVNOTE_PATH=/home/jovyan/work/devnotes/template

echo "Setting up environment"
ls -alh /opt
ls -alh /opt/repo

# Bring down and update our baseline home directory
if [ ! -d ${REPO} ]; then
    git clone --depth=1 ${GIT_REMOTE} ${REPO}
fi
cd ${REPO}
git remote set-url origin ${GIT_REMOTE} # Fix up remote if image was built from a repo with an SSH origin.
git pull

#rsync -av ${REPO}/home-overlay/ ${HOME}

# Update our jupyter configuration
cat ${REPO}/config/jupyter_server_config_additional.py >> ${HOME}/.jupyter/jupyter_server_config.py
mkdir -p ${JUPYTER_SETTINGS}
cp ${REPO}/config/overrides.json ${JUPYTER_SETTINGS}/overrides.json

# Install our key packages
~/.local/bin/uv pip install --system -e ${REPO}/nucleus-env

# Bring down the curvenote template
# if [ -d ${DEVNOTE_PATH} ]; then 
#     cd ${DEVNOTE_PATH}
#     git pull --ff-only 
# else
#     git clone --depth=1 https://github.com/antonrmolina/devnote-template.git ${DEVNOTE_PATH}
# fi

# Create LSP symlink
echo Creating symlink
if [ ! -L ${HOME}/work/.lsp_symlink ]; then
    ln -s / ${HOME}/work/.lsp_symlink
fi

echo Nucleus environment setup