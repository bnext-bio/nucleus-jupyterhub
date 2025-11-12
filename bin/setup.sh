#!/bin/bash

HOME=/home/jovyan
JUPYTER_SETTINGS=/opt/conda/share/jupyter/lab/settings
DEVNOTE_PATH=/home/jovyan/work/devnotes/template

echo "Setting up environment"
echo "Running as: `whoami`"
echo "NB_USER: $NB_USER"
echo "NB_UID: $NB_UID"
echo "NB_GID: $NB_GID"
echo "NB_UMASK: $NB_UMASK"
echo "UV_INDEX: $UV_INDEX"

cd ${REPO}

# Bring down and update our baseline home directory
echo "Updating home directory overlay."
rsync -a ${REPO}/home-overlay/ ${HOME}

# Install shell basics if necessary
zsh -ci "source /opt/antidote/antidote.zsh && antidote load"

# Update our jupyter configuration
echo "Updating jupyter configuration"
cat ${REPO}/config/jupyter_server_config_additional.py >> ${HOME}/.jupyter/jupyter_server_config.py
mkdir -p ${JUPYTER_SETTINGS}
cp ${REPO}/config/overrides.json ${JUPYTER_SETTINGS}/overrides.json

# Install LSP into node roots using npm
mkdir -p /opt/noderoots
cd /opt/noderoots
npm install --save-dev unified-language-server

cd ${REPO}

# Drop in launcher configuration for the collaboration groups we're a part of
# echo "Creating collaboration launchers for user groups"
# if [[ ! $JUPYTERHUB_USER =~ "-collab" ]]; then
#     for group in `curl -H "Authorization: token $JUPYTERHUB_API_TOKEN" $JUPYTERHUB_API_URL/user | jq -r '.groups | join("\n")'`; do
#         echo "Creating launcher for group: ${group}"
#         echo """
# - title: \"Collab: ${group}\"
#   description: Open the real-time collaboration server for ${group}
#   source: /user/${group}-collab
#   type: url
#   catalog: Nucleus
#   args:
#     createNewWindow: true
# """ > ${HOME}/.local/share/jupyter/jupyter_app_launcher/jp_app_launcher_collab_${group}.yml
#     done
# else
#     echo "Already in collaborative user: not creating launcher"
# fi

# Add topbar text to indicate the user
echo "Adding topbar configuration"
mkdir -p ${HOME}/.jupyter/lab/user-settings/jupyterlab-topbar-text/
TOPBAR_TAG="👤 ${JUPYTERHUB_USER}"
if [[ $JUPYTERHUB_USER =~ "-collab" ]]; then
    TOPBAR_TAG="🌎 ${JUPYTERHUB_USER%-collab}"
fi
echo """{
    \"text\": \"${TOPBAR_TAG}\",
    \"editable\": false
}""" > ${HOME}/.jupyter/lab/user-settings/jupyterlab-topbar-text/plugin.jupyterlab-settings

# Install our key packages
echo "Installing environment packages"
uv pip install --system -e ${REPO}/nucleus-env --no-progress

# Bring down the curvenote template
echo "Updating curvenote template"
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

cd ${HOME}
echo PWD: `pwd`

echo Nucleus environment setup