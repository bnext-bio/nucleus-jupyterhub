#!/bin/bash

JUPYTER_SETTINGS=/opt/conda/share/jupyter/lab/settings
DEVNOTE_PATH=${HOME}/work/devnotes/template

echo "Setting up environment"
echo "Running as: `whoami`"
echo "NB_USER: $NB_USER"
echo "NB_UID: $NB_UID"
echo "NB_GID: $NB_GID"
echo "NB_UMASK: $NB_UMASK"
echo "UV_INDEX: $UV_INDEX"
echo "HOME: $HOME"

cd ${REPO}

# Bring down and update our baseline home directory
echo "Updating home directory overlay."
cp -Rv ${REPO}/home-overlay/. ${HOME}

# Update our jupyter configuration
echo "Updating jupyter configuration"
cat ${REPO}/config/jupyter_server_config_additional.py > ${HOME}/.jupyter/jupyter_server_config.py
mkdir -p ${JUPYTER_SETTINGS}
cp ${REPO}/config/overrides.json ${JUPYTER_SETTINGS}/overrides.json

# Update our CDK package environment
${REPO}/bin/update-packages.sh

cd ${REPO}

USER_STUB="${JUPYTERHUB_USER#*:}"

# Drop in launcher configuration for the collaboration groups we're a part of
# echo "Creating collaboration launchers for user groups"
# if [[ ! $USER_STUB =~ "-collab" ]]; then
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

# # Add topbar text to indicate the user
# echo "Adding topbar configuration"
# mkdir -p ${HOME}/.jupyter/lab/user-settings/jupyterlab-topbar-text/
# TOPBAR_TAG="👤 ${USER_STUB}"
# if [[ $JUPYTERHUB_USER =~ "-collab" ]]; then
#     TOPBAR_TAG="🌎 ${USER_STUB%-collab}"
# fi
# echo """{
#     \"text\": \"${TOPBAR_TAG}\",
#     \"editable\": false
# }""" > ${HOME}/.jupyter/lab/user-settings/jupyterlab-topbar-text/plugin.jupyterlab-settings

cd ${HOME}
echo PWD: `pwd`

echo Nucleus environment setup