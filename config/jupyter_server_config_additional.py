
# Additional configuration for the nucleus jupyter environment
# c.Application.log_level = "DEBUG"

c.LabApp.custom_css = True

c.JupyterLabTemplates.allowed_extensions = ["*.ipynb"]
c.JupyterLabTemplates.template_dirs = ["/home/jovyan/work/shared/.templates"]
c.JupyterLabTemplates.include_default = False
c.JupyterLabTemplates.include_core_paths = True
c.JupyterLabTemplates.template_label = "Template"

c.ContentsManager.allow_hidden = True

c.ServerProxy.servers = {
    "curvenote-start": {
        "command": ["/bin/bash", "/opt/repo/bin/curvenote-launch.sh", "{port}"],
        "absolute_url": False,
        "environment": {
            "BASE_URL_PREFIX": "{base_url}/curvenote-start"
        },
        "timeout": 120,
        "launcher_entry": {
            "enabled": True,
            "title": "Curvenote Preview",
            "category": "Nucleus",
            "icon_path": "/opt/repo/share/curvenote-logo.svg"
        },
        "new_browser_tab": False
    }
}

# Set default terminal shell
c.NotebookApp.terminado_settings = { "shell_command": ["/bin/zsh"] }