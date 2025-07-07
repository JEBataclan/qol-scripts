#!/usr/bin/env bash

set -e

# Determine OS
OS="$(uname -s)"
INSTALL_DIR=""

if [[ "$OS" == "Darwin" ]]; then
  INSTALL_DIR="$HOME/.local/bin/omnisharp"
  ZIP_URL="https://github.com/OmniSharp/omnisharp-roslyn/releases/latest/download/omnisharp-osx.zip"
  BINARY_NAME="OmniSharp"
# elif [[ "$OS" == "Linux" ]]; then
#   INSTALL_DIR="$HOME/.local/bin/omnisharp"
#   ZIP_URL="https://github.com/OmniSharp/omnisharp-roslyn/releases/latest/download/omnisharp-linux-x64.zip"
#   BINARY_NAME="OmniSharp"
# elif [[ "$OS" == "MINGW"* || "$OS" == "MSYS"* || "$OS" == "CYGWIN"* ]]; then
#   INSTALL_DIR="$HOME/AppData/Local/omnisharp"
#   ZIP_URL="https://github.com/OmniSharp/omnisharp-roslyn/releases/latest/download/omnisharp-win-x64.zip"
#   BINARY_NAME="OmniSharp.exe"
else
  echo "Unsupported OS: $OS"
  exit 1
fi

# Install
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
curl -L -o omnisharp.zip "$ZIP_URL"
unzip -o omnisharp.zip
chmod +x "$BINARY_NAME"
rm omnisharp.zip

echo "OmniSharp installed to: $INSTALL_DIR/$BINARY_NAME"
