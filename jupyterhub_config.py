# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Configuration file for JupyterHub
import os

from jupyterhub.orm import User, Group
from jupyterhub.app import JupyterHub
from dockerspawner import DockerSpawner, SystemUserSpawner

c = get_config()  # noqa: F821

# Hub Configuration
# -----------------
c.Application.log_level = os.environ.get("HUB_LOG_LEVEL", "INFO")
c.JupyterHub.log_level = os.environ.get("HUB_LOG_LEVEL", "INFO")

c.JupyterHub.hub_ip = "hub"
c.JupyterHub.hub_port = 8080

c.JupyterHub.cookie_secret_file = "/data/jupyterhub_cookie_secret"
c.JupyterHub.db_url = "sqlite:////data/jupyterhub.sqlite"

# Authentication
# --------------

c.JupyterHub.authenticator_class = "generic-oauth"

c.GenericOAuthenticator.client_id = os.environ["HUB_OAUTH_CLIENT_ID"]
c.GenericOAuthenticator.client_secret = os.environ["HUB_OAUTH_CLIENT_SECRET"]

c.GenericOAuthenticator.authorize_url = os.environ["HUB_OAUTH_AUTH_URL"]
c.GenericOAuthenticator.token_url = os.environ["HUB_OAUTH_TOKEN_URL"]
c.GenericOAuthenticator.userdata_url = os.environ["HUB_OAUTH_USERDATA_URL"]

c.GenericOAuthenticator.scope = ["openid", "email", "profile"]
c.GenericOAuthenticator.username_claim = "preferred_username"
c.GenericOAuthenticator.auth_state_groups_key = "oauth_user.groups"
c.GenericOAuthenticator.manage_groups = True

c.GenericOAuthenticator.allowed_users = set()
c.GenericOAuthenticator.allowed_groups = {"hub-users"}
c.GenericOAuthenticator.admin_users = set()
c.GenericOAuthenticator.admin_groups = {"hub-admins"}

# Spawner Configuration
# ---------------------
class NestedHomeSpawner(SystemUserSpawner):
    @property
    def volume_binds(self):
        # Bypass SystemUserSpawner's forced host_home -> homedir bind;
        # we manage the layering ourselves via c.DockerSpawner.volumes.
        return DockerSpawner.volume_binds.fget(self)

c.JupyterHub.spawner_class = NestedHomeSpawner

# c.JupyterHub.spawner_class = "dockerspawner.SystemUserSpawner"

c.DockerSpawner.volumes = {
    'nucleushub-user-{username}':   '/home/{username}',          # dotfiles, caches
    '/mnt/ssd/users/{username}':    '/home/{username}/home',     # real host data
    '/mnt/storage/data':            '/home/{username}/data',
    '/mnt/storage/scratch/groups':  '/home/{username}/groups',
    '/var/lib/sss/pipes':           '/var/lib/sss/pipes'
}

c.DockerSpawner.read_only_volumes = {
    '/var/lib/sss/mc':      '/var/lib/sss/mc',
    '/etc/nsswitch.conf':   '/etc/nsswitch.conf'
}

c.SystemUserSpawner.environment = {
    'NB_USER':         '{username}',
    'NB_UID':          '{userid}',     # populated by SystemUserSpawner
    'NB_GID':          '{groupid}',    # ditto if your version exposes it; otherwise hardcode or compute
    'CHOWN_HOME':      'yes',
    'CHOWN_HOME_OPTS': '',
    'CHOWN_EXTRA': '/opt/repo,/opt/noderoots'
    # Critically: do NOT set CHOWN_EXTRA to include the bind-mounted host path
}

# c.SystemUserSpawner.host_homedir_format_string = '/mnt/ssd/users/{username}/hub'
c.SystemUserSpawner.run_as_root = True

c.DockerSpawner.image = os.environ["HUB_NOTEBOOK_IMAGE"]
c.DockerSpawner.prefix = "nucleushub"
c.DockerSpawner.start_timeout = 300

# if "NB_USER" in os.environ:
#     c.DockerSpawner.extra_create_kwargs = {"user": os.environ["NB_USER"]}
#     c.DockerSpawner.extra_host_config = {"group_add": ["users"]}

c.DockerSpawner.env_keep.extend(["UV_INDEX", "NB_UMASK"])

c.DockerSpawner.use_internal_ip = True
c.DockerSpawner.network_name = os.environ["HUB_NETWORK_NAME"]

# Explicitly set notebook directory because we'll be mounting a volume to it.
# Most `jupyter/docker-stacks` *-notebook images run the Notebook server as
# user `jovyan`, and set the notebook directory to `/home/jovyan/work`.
# We follow the same convention.
# notebook_dir = os.environ.get("HUB_NOTEBOOK_DIR", "/home/jovyan")
c.DockerSpawner.notebook_dir = "~/"
# c.DockerSpawner.volumes = {
#     "nucleushub-user-{username}": notebook_dir
# }

c.DockerSpawner.remove = False
c.DockerSpawner.debug = True

# Permissions for sharing / RTC
# c.JupyterHub.load_roles = [
#     {
#         "name": "user",
#         "scopes": [
#             "self",
#             "shares!user",
#             "read:users:name",
#             "read:groups:name",
#             "access:servers",
#         ],
#     },
# ]

# c.DockerSpawner.oauth_client_allowed_scopes = ["access:servers!server", "shares!server"]