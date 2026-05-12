import os
# Additional configuration for the nucleus jupyter environment
# c.Application.log_level = "DEBUG"

# Launch in home directory
home_dir = os.environ.get("HOME", "/home/jovyan")
# c.ServerApp.root_dir = home_dir 

# Extra node roots so we can install the language server
c.LanguageServerManager.extra_node_roots = [
    "/opt/noderoots",
    "/opt/conda/lib"
]

c.LabApp.custom_css = True

c.JupyterLabTemplates.allowed_extensions = ["*.ipynb"]
c.JupyterLabTemplates.template_dirs = [
    "/opt/repo/templates",
    f"{home_dir}/shared/templates",
]
c.JupyterLabTemplates.include_default = False
c.JupyterLabTemplates.include_core_paths = True
c.JupyterLabTemplates.template_label = "Template"

# File config
c.ContentsManager.allow_hidden = True
c.FileContentsManager.always_delete_dir = True

# Set default terminal shell
c.NotebookApp.terminado_settings = {"shell_command": ["/bin/zsh"]}

# Server proxies
c.ServerProxy.servers = {
    "copyparty": {
        "command": ["/opt/repo/bin/copyparty.sh", "{port}"],
        "absolute_url": True,
        "new_browser_tab": True,
        "launcher_entry": {
            "enabled": False
        }
    }
}