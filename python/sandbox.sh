#!/bin/bash

#==============================================================================
# Script Name    : build_ubuntu.sh
# Description    : This script sets up the Python sandbox environment with
#                  JupyterLab.
#
# Author         : Alan MARCHAND
# Compatibility  : Bash Only
#==============================================================================

#!/bin/bash

#==============================================================================
# Script Name    : build_ubuntu.sh
# Description    : This script sets up a Python development environment with
#                  JupyterLab pre-configured for web access.
# Author         : Alan MARCHAND
# Compatibility  : Bash Only
#==============================================================================

# Define workspace directory (Modify if needed)
WORKSPACE_DIR=~/Workspaces

# Ensure workspace directory exists
if [ -d "$WORKSPACE_DIR" ]; then
  echo "Removing existing workspace directory: $WORKSPACE_DIR"
  rm -rf "$WORKSPACE_DIR"
fi

echo "Creating workspace directory: $WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR"

# Create the sandbox project
echo "Creating sandbox project..."
uv init $WORKSPACE_DIR/sandbox

# Create the sandbox virtual environment
echo "Creating sandbox virtual environement..."
cd $WORKSPACE_DIR/sandbox
uv venv

source "./.venv/bin/activate"

# Add dependencies
echo "Installing dependencies..."
uv add requests jupyterlab numpy pandas numpy seaborn

# Detect if running in WSL (Windows Subsystem for Linux)
if grep -qEi "(Microsoft|WSL)" /proc/version &>/dev/null; then
  echo "WSL detected. Configuring JupyterLab for web access..."

  JLCONFIG=~/.jupyter/jupyter_lab_config.py

  # Clean-up existing configurations (if any)
  rm -rf "$JLCONFIG" ~/.jupyter ~/.local/share/jupyter ~/.ipython &>/dev/null

  # Generate JupyterLab configuration and disable file redirection
  jupyter lab --generate-config -y
  sed -i 's/^#\s\(c.ServerApp.use_redirect_file.*\)$/\1/' "$JLCONFIG"
  sed -i 's/^\(c.ServerApp.use_redirect_file\s\).*$/\1= False/' "$JLCONFIG"
  
  echo "JupyterLab configured for WSL."
else
  echo "Running on native Linux. Skipping JupyterLab web configuration."
fi

# Install JavaScript Kernel (Optional, for non-Python code) if Node.js is installed
if command -v node &>/dev/null; then
  echo "Node.js is installed. Checking for JavaScript Kernel..."
  x=$(npm list -g ijavascript)
  if [[ $? -gt 0 ]]; then
    echo "Installing JavaScript Kernel..."
    npm install -g ijavascript  # May require sudo
    cd "$WORKSPACE_DIR"
    ijsinstall
  fi
else
  echo "Node.js is not installed. Skipping JavaScript Kernel installation."
fi

# Deactivate virtual environment and return to home directory
echo "Deactivating virtual environment..."
deactivate
cd ~

echo "Python development environment with JupyterLab is ready!"
