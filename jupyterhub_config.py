# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Configuration file for JupyterHub
import os

c = get_config()  # noqa: F821

# We rely on environment variables to configure JupyterHub so that we
# avoid having to rebuild the JupyterHub container every time we change a
# configuration parameter.

# c.Application.log_level = "DEBUG"
# c.JupyterHub.log_level = "DEBUG"

# Spawn single-user servers as Docker containers
c.JupyterHub.spawner_class = "dockerspawner.DockerSpawner"

# Spawn containers from this image
c.DockerSpawner.image = os.environ["DOCKER_NOTEBOOK_IMAGE"]

# Set timeout high since we might be doing a lot of warmup on the server
c.DockerSpawner.start_timeout = 300

if "NB_USER" in os.environ:
    c.DockerSpawner.extra_create_kwargs = {
        "user": os.environ["NB_USER"]
    }
    c.DockerSpawner.extra_host_config = {
        "group_add": ["users"]
    }

c.DockerSpawner.env_keep.extend([
    "UV_INDEX",
    "NB_UMASK"
])

# Connect containers to this Docker network
network_name = os.environ["DOCKER_NETWORK_NAME"]
c.DockerSpawner.use_internal_ip = True
c.DockerSpawner.network_name = network_name

# Explicitly set notebook directory because we'll be mounting a volume to it.
# Most `jupyter/docker-stacks` *-notebook images run the Notebook server as
# user `jovyan`, and set the notebook directory to `/home/jovyan/work`.
# We follow the same convention.
notebook_dir = os.environ.get("DOCKER_NOTEBOOK_DIR", "/home/jovyan/work")
c.DockerSpawner.notebook_dir = notebook_dir

# Mount the real user's Docker volume on the host to the notebook user's
# notebook directory in the container
c.DockerSpawner.volumes = {
    "jupyterhub-user-{username}": notebook_dir,
    os.environ.get("DATA_DIRECTORY", "jupyterhub-shared-data"): "/home/jovyan/work/shared"
}

# Run our post-setup script
# c.DockerSpawner.post_start_cmd = "/opt/repo/bin/setup.sh"

# Remove containers once they are stopped
c.DockerSpawner.remove = True

# For debugging arguments passed to spawned containers
c.DockerSpawner.debug = True

# User containers will access hub by container name on the Docker network
c.JupyterHub.hub_ip = "jupyterhub"
c.JupyterHub.hub_port = 8080

# Persist hub data on volume mounted inside container
c.JupyterHub.cookie_secret_file = "/data/jupyterhub_cookie_secret"
c.JupyterHub.db_url = "sqlite:////data/jupyterhub.sqlite"

# Allow all signed-up users to login
c.Authenticator.allow_all = True

# Authenticate users with Native Authenticator
c.JupyterHub.authenticator_class = "nativeauthenticator.NativeAuthenticator"

# Allow anyone to sign-up without approval
c.NativeAuthenticator.open_signup = False

# Additional config
c.NativeAuthenticator.allowed_failed_logins = 3
c.NativeAuthenticator.ask_email_on_signup = True

# Allowed admins
admin = os.environ.get("JUPYTERHUB_ADMIN")
if admin:
    c.Authenticator.admin_users = [admin]

# Permissions for sharing / RTC
c.JupyterHub.load_roles = [
    {
        "name": "user",
        "scopes": ["self", "shares!user", "read:users:name", "read:groups:name", "access:servers"],
    },
]

c.DockerSpawner.oauth_client_allowed_scopes = ["access:servers!server", "shares!server"]
