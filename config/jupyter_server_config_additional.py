# Additional configuration for the nucleus jupyter environment
# c.Application.log_level = "DEBUG"

# Launch in home directory
c.ServerApp.root_dir = "/home/jovyan"

# Extra node roots so we can install the language server
c.LanguageServerManager.extra_node_roots = ["/opt/noderoots"]

c.LabApp.custom_css = True

c.JupyterLabTemplates.allowed_extensions = ["*.ipynb"]
c.JupyterLabTemplates.template_dirs = [
    "/opt/repo/templates",
    # "/home/jovyan/shared/templates",
]
c.JupyterLabTemplates.include_default = False
c.JupyterLabTemplates.include_core_paths = True
c.JupyterLabTemplates.template_label = "Template"

# File config
c.ContentsManager.allow_hidden = True
c.FileContentsManager.always_delete_dir = True

c.ServerProxy.servers = {}

# Set default terminal shell
c.NotebookApp.terminado_settings = {"shell_command": ["/bin/zsh"]}
