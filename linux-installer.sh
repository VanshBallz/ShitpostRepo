#!/data/data/com.termux/files/usr/bin/bash

pkg update -y
pkg install x11-repo -y
pkg install proot-distro termux-x11-nightly pulseaudio virglrenderer-android wget -y

echo "Select Linux Distribution:"
echo "1) Debian"
echo "2) Ubuntu"
read -p "Enter choice [1-2]: " DISTRO_CHOICE

if [ "$DISTRO_CHOICE" -eq 1 ]; then
    DISTRO="debian"
elif [ "$DISTRO_CHOICE" -eq 2 ]; then
    DISTRO="ubuntu"
else
    echo "Invalid selection."
    exit 1
fi

echo "Select Desktop Environment:"
echo "1) XFCE4"
echo "2) KDE Plasma"
read -p "Enter choice [1-2]: " DE_CHOICE

if [ "$DE_CHOICE" -eq 1 ]; then
    DE_PKG="xfce4 xfce4-terminal"
    DE_CMD="startxfce4"
elif [ "$DE_CHOICE" -eq 2 ]; then
    DE_PKG="kde-plasma-desktop"
    DE_CMD="startplasma-x11"
else
    echo "Invalid selection."
    exit 1
fi

read -p "Enter desired username: " USERNAME

proot-distro install "$DISTRO"

proot-distro login "$DISTRO" -- /bin/bash -c "apt update -y && apt install sudo nano adduser -y && adduser --disabled-password --gecos '' $USERNAME && echo '$USERNAME ALL=(ALL:ALL) ALL' >> /etc/sudoers"

echo "Set a password for $USERNAME:"
proot-distro login "$DISTRO" -- /bin/bash -c "passwd $USERNAME"

proot-distro login "$DISTRO" -- /bin/bash -c "apt update -y && apt install $DE_PKG -y"

cat << EOF > start.sh
#!/data/data/com.termux/files/usr/bin/bash
virgl_test_server_android &
sleep 2
kill -9 \$(pgrep -f "termux.x11") 2>/dev/null
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
export XDG_RUNTIME_DIR=\${TMPDIR}
termux-x11 :0 >/dev/null &
sleep 3
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1
proot-distro login $DISTRO --shared-tmp -- /bin/bash -c 'export PULSE_SERVER=127.0.0.1 && export XDG_RUNTIME_DIR=\${TMPDIR} && su - $USERNAME -c "env DISPLAY=:0 GALLIUM_DRIVER=virpipe MESA_GL_VERSION_OVERRIDE=4.0 $DE_CMD"'
exit 0
EOF

chmod +x start.sh

echo "Installation complete! Run ./start.sh to launch your session."
        DE_PKG="kde-plasma-desktop"
        DE_CMD="startplasma-x11"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# 3. Prompt for Username
echo ""
read -rp "Enter username to create in $DISTRO: " USERNAME

if [ -z "$USERNAME" ]; then
    echo "Username cannot be empty. Exiting."
    exit 1
fi

# 4. Install Termux Dependencies
echo ""
echo "[1/4] Installing Termux dependencies..."
pkg update -y
pkg install -y x11-repo
pkg install -y termux-x11-nightly pulseaudio wget proot-distro

# 5. Install Distro via proot-distro
echo ""
echo "[2/4] Setting up $DISTRO environment..."
proot-distro install "$DISTRO" || echo "$DISTRO is already installed, proceeding..."

# 6. Configure User and Install DE inside PRoot
echo ""
echo "[3/4] Installing $DE_NAME and setting up user '$USERNAME' in $DISTRO..."
proot-distro login "$DISTRO" -- /bin/bash -c "
    apt update -y
    apt install -y sudo nano adduser $DE_PKG

    # Create user if it doesn't already exist
    if ! id '$USERNAME' &>/dev/null; then
        adduser '$USERNAME'
    fi

    # Grant sudo privileges
    if ! grep -q '$USERNAME ALL=(ALL:ALL) ALL' /etc/sudoers; then
        echo '$USERNAME ALL=(ALL:ALL) ALL' >> /etc/sudoers
    fi
"

# 7. Create Custom Startup Script
SCRIPT_NAME="start_${DISTRO}_${DE_PKG}.sh"
echo ""
echo "[4/4] Creating startup script: $SCRIPT_NAME..."

cat <<EOF > "$SCRIPT_NAME"
#!/data/data/com.termux/files/usr/bin/bash

# Kill open X11 processes
kill -9 \$(pgrep -f "termux.x11") 2>/dev/null

# Enable PulseAudio over Network
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

# Prepare termux-x11 session
export XDG_RUNTIME_DIR=\${TMPDIR}
termux-x11 :0 >/dev/null &

# Wait a bit until termux-x11 gets started.
sleep 3

# Launch Termux X11 main activity
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

# Login in PRoot Environment and launch $DE_NAME
proot-distro login $DISTRO --shared-tmp -- /bin/bash -c 'export PULSE_SERVER=127.0.0.1 && export XDG_RUNTIME_DIR=\${TMPDIR} && su - $USERNAME -c "env DISPLAY=:0 $DE_CMD"'

exit 0
EOF

chmod +x "$SCRIPT_NAME"

echo ""
echo "=============================================="
echo "         Installation Completed!              "
echo "=============================================="
echo "To launch your desktop environment, run:"
echo "  ./$SCRIPT_NAME"
echo "=============================================="
