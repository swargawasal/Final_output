#!/bin/bash

echo "🤖 Termux Auto-Setup for Transformative Bot (Universal Edition)"
echo "=========================================================="

echo "📦 Updating repositories..."
pkg update -y && pkg upgrade -y

echo "📦 Installing System Dependencies & Python..."
# Core build tools, python, git, and media libraries
# We use 'python' (rolling release) instead of forcing 'python3.10' which often vanishes.
# We also install 'python-numpy' and 'opencv' (python-opencv) from REPO as compiling them on phone is painful.

# 1. Enable TUR (Termux User Repo) just in case, but rely on main first.
pkg install -y tur-repo 

# 2. Key Binary Dependencies
# rust/binutils/build-essential: For compiling cryptography/pillow/etc.
# openjpeg/libjpeg-turbo: For Pillow
# ffmpeg: For video
pkg install -y python git clang make binutils rust
pkg install -y cmake ninja libffi libjpeg-turbo libpng freetype libxml2 libxslt zlib 
pkg install -y ffmpeg

# 3. Python Science Stack (Pre-compiled via Termux)
# CRITICAL: Installing these via pkg prevents 30min+ compilation failures
echo "📦 Installing Pre-compiled Science Stack..."
pkg install -y python-numpy opencv python-opencv

echo "🛠️ Creating Virtual Environment (venv)..."

# Detect Python Executable
PY_EXEC="python"
if command -v python3 &> /dev/null; then
    PY_EXEC="python3"
fi

echo "   └─ Detected Python: $PY_EXEC ($( $PY_EXEC --version ))"

if [ ! -d "venv" ]; then
    # CRITICAL: --system-site-packages
    # This allows venv to see the 'python-numpy' and 'cv2' we just installed via pkg.
    $PY_EXEC -m venv --system-site-packages venv
    echo "   └─ Created 'venv' (System Packages: Enabled)"
else
    echo "   └─ 'venv' already exists. Skipping creation."
fi

echo "🔌 Activating venv..."
source venv/bin/activate

echo "📦 Upgrading pip (inside venv)..."
pip install --upgrade pip

echo "🔧 Relaxing Strict Requirements for Termux..."
# We unpin numpy/opencv in requirements.txt temporarily for this install session
# to ensure we don't try to downgrade the system packages we just installed.
if [ -f "requirements.txt" ]; then
    # Backup
    cp requirements.txt requirements.termux.bak
    
    # Remove strict pinning for numpy and opencv to allow system versions
    sed -i 's/numpy==.*//g' requirements.txt
    sed -i 's/opencv-python.*//g' requirements.txt
    # Also remove blank lines created
    sed -i '/^$/d' requirements.txt
    
    echo "   └─ Patched requirements.txt to allow System NumPy/OpenCV"
fi

echo "📦 Installing Python Dependencies (inside venv)..."
# Flag to force compile if wheels missing
export CFLAGS="-Wno-error=incompatible-function-pointer-types -Wno-implicit-function-declaration"

# Install everything else
pip install -r requirements.txt

# Restore original requirements (optional, but good practice)
if [ -f "requirements.termux.bak" ]; then
    mv requirements.termux.bak requirements.txt
fi

echo "=========================================================="
echo "✅ Setup Complete!"
echo ""
echo "❗ IMPORTANT ❗"
echo "To run the bot, you must activate the environment first:"
echo "   source venv/bin/activate"
echo "   python main.py"
echo ""
echo "Or run in one line:"
echo "   ./venv/bin/python main.py"
