#!/bin/bash

HOME=/home/jovyan
GIT_REMOTE="https://github.com/bnext-bio/nucleus-jupyterhub.git"
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

# Update our jupyter configuration
echo "Updating jupyter configuration"
cat ${REPO}/config/jupyter_server_config_additional.py >> ${HOME}/.jupyter/jupyter_server_config.py
mkdir -p ${JUPYTER_SETTINGS}
cp ${REPO}/config/overrides.json ${JUPYTER_SETTINGS}/overrides.json

# Drop in launcher configuration for the collaboration groups we're a part of
echo "Creating collaboration launchers for user groups"
for group in `curl -H "Authorization: token $JUPYTERHUB_API_TOKEN" $JUPYTERHUB_API_URL/user | jq -r '.groups | join("\n")'`; do
    echo "Creating launcher for group: ${group}"
    echo """
- title: "Collab: ${group}"
  description: Open the real-time collaboration server for ${group}
  source: /hub/spawn/${group}-collab
  type: url
  catalog: Nucleus
  args:
      createNewWindow: true
""" > ${HOME}/.local/share/jupyter/jupyter_app_launcher/jp_app_launcher_collab_${group}.yml
done

# Install our key packages
echo "Installing environment packages"
~/.local/bin/uv pip install --system -e ${REPO}/nucleus-env --no-progress

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

# Create LSP symlink
echo Creating symlink
if [ ! -L ${HOME}/work/.lsp_symlink ]; then
    ln -s / ${HOME}/work/.lsp_symlink
fi

# Create curvenote symlink
echo Linking curvenote config
if [ ! -L ${HOME}/.curvenote ]; then
    ln -s ${HOME}/work/.curvenote ~/.curvenote
fi

# Run final shared setup commands
echo Running final setup
if [ -f ${HOME}/work/shared/.setup/setup.sh ]; then
    ${HOME}/work/shared/.setup/setup.sh
fi

echo Nucleus environment setup