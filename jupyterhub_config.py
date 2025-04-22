# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

# Configuration file for JupyterHub
import os
import nativeauthenticator

from jupyterhub.orm import User, Group
from jupyterhub.app import JupyterHub

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
c.JupyterHub.template_paths = [f"{os.path.dirname(nativeauthenticator.__file__)}/templates/"]

# Allow anyone to sign-up without approval
c.NativeAuthenticator.open_signup = False

# Additional config
c.NativeAuthenticator.allowed_failed_logins = 3
c.NativeAuthenticator.ask_email_on_signup = True

# Allowed admins
admin = os.environ.get("JUPYTERHUB_ADMIN")
if admin:
    c.Authenticator.admin_users = ["admin", "acjs", "molina"]

# Permissions for sharing / RTC
c.JupyterHub.load_roles = [
    {
        "name": "user",
        "scopes": ["self", "shares!user", "read:users:name", "read:groups:name", "access:servers"],
    },
]

c.DockerSpawner.oauth_client_allowed_scopes = ["access:servers!server", "shares!server"]


# Collaboration group setup
# Experimentally vibe-coded based on https://jupyterhub.readthedocs.io/en/latest/tutorial/collaboration-users.html

def create_collaboration_users():
    """
    Create collaboration users for all groups with collaboration=True property
    """
    app = JupyterHub.instance()
    db = app.db
    
    # Setup for our collaborative users group
    collab_group_name = "collaborative"
    collab_group = db.query(Group).filter_by(name=collab_group_name).first()
    if not collab_group:
        app.log.info(f"Creating collaborative group '{collab_group_name}'")
        collab_group = Group(name=collab_group_name)
        db.add(collab_group)
        db.commit()
    
    # Get all groups from the database
    all_groups = db.query(Group).all()
    
    # Initialize roles list if not already present
    if not hasattr(c.JupyterHub, 'load_roles'):
        c.JupyterHub.load_roles = []
    
    for group in all_groups:
        # Check if this group has the collaboration property set to True
        # Since Group doesn't have a 'collaboration' property by default,
        # we'll check a custom data attribute that needs to be set elsewhere
        # (e.g., via an admin API extension or custom database modification)
        
        # Option 1: Check if the group has a data property
        has_collab_flag = False
        
        # If you've extended the Group model with a 'properties' or 'data' field:
        if hasattr(group, 'properties') and isinstance(group.properties, dict) and group.properties.get('collaboration').lower() == "true":
            has_collab_flag = True
        
        # Option 2: Check based on naming convention (e.g., groups prefixed with "collab-")
        # if group.name.startswith("collab-"):
        #     has_collab_flag = True
            
        # Option 3: Check against a predefined list of collaboration groups
        # collab_group_names = ["group1", "group2", "group3"]
        # if group.name in collab_group_names:
        #     has_collab_flag = True
        
        if has_collab_flag:
            # Create collaboration user for this group if it doesn't exist already
            collab_username = f"{group.name}-collab"
            collab_user = db.query(User).filter_by(name=collab_username).first()
            
            if not collab_user:
                app.log.info(f"Creating collaboration user '{collab_username}' for group '{group.name}'")
                collab_user = app.authenticator.add_user(collab_username)
                
                # Add to the collaborative group
                collab_user.groups.append(collab_group)
                db.commit()
            
            # Get the members of the group
            members = [user.name for user in group.users]
            app.log.info(f"Group '{group.name}' has members: {members}")
            
            # Create the role for access to the collab user's server
            role_name = f"collab-access-{group.name}"
            
            # Check if the role already exists in load_roles
            role_exists = any(role.get('name') == role_name for role in c.JupyterHub.load_roles)
            
            if not role_exists:
                app.log.info(f"Creating collaboration role '{role_name}'")
                c.JupyterHub.load_roles.append({
                    "name": role_name,
                    "scopes": [
                        f"access:servers!user={collab_username}",
                        f"admin:servers!user={collab_username}",
                        "admin-ui",
                        f"list:users!user={collab_username}",
                    ],
                    "groups": [group.name],
                })
        
        
# Enable real-time collaboration for collaborative users
def pre_spawn_hook(spawner):
    create_collaboration_users()
    
    user = spawner.user
    group_names = {group.name for group in user.groups}
    
    if "collaborative" in group_names:
        spawner.log.info(f"Enabling collaborative mode for user {user.name}")
        spawner.args.append("--LabApp.collaborative=True")
        
        # Additional collaboration-specific configurations can be added here
        # For example, mounting shared data directories, etc.

c.Spawner.pre_spawn_hook = pre_spawn_hook