#!/bin/bash

# 1. Ask for username and password first
echo "=== Termux Debian & XFCE4 Setup ==="
read -p "Enter your desired Debian username: " USERNAME
read -s -p "Enter your desired Debian password: " PASSWORD
echo ""
echo "Credentials saved for installation."
echo ""

# 2. Termux setup storage first
echo "Setting up Termux storage..."
echo "Please click 'Allow' if a permissions pop-up appears on your screen."
termux-setup-storage
sleep 5 # Pauses to give you time to accept the prompt

# 3. Update Termux and install required packages
echo "Updating Termux and installing dependencies..."
pkg update && pkg upgrade -y
pkg install x11-repo tur-repo -y
pkg install termux-x11-nightly wget pulseaudio proot-distro mesa-zink virglrenderer-mesa-zink vulkan-loader-android virglrenderer-android -y

# 4. Install Debian via proot-distro
echo "Installing Debian..."
pd i debian

# 5. Instructions for XFCE4 setup
echo ""
echo "========================================================================"
echo "                            ATTENTION!                                  "
echo "During the next step (XFCE4 installation), the terminal will pause and  "
echo "ask you to configure your region, timezone, and keyboard layout.        "
echo "                                                                        "
echo "Please do the following when prompted:                                  "
echo "1. Geographic area: Choose 'Asia' (you may need to press 'More' several times)."
echo "2. Time zone: Choose 'Kolkata'.                                         "
echo "3. Keyboard layout: Choose 'Plain English' (or 'English US').           "
echo "========================================================================"
echo "Starting Debian configuration in 10 seconds. Read the instructions above!"
sleep 10

# 6. Execute commands inside Debian Proot
# We use bash -c to run the sequence of commands inside the Debian environment
# useradd and chpasswd are used to automate the account creation with the password you entered
pd login debian --shared-tmp -- bash -c "
  apt update && apt upgrade -y
  apt install sudo adduser xfce4 xfce4-goodies xfce4-terminal dbus-x11 -y
  apt update && apt upgrade -y
  
  # Automating user creation with the provided username and password
  useradd -m -s /bin/bash \"$USERNAME\"
  echo \"$USERNAME:$PASSWORD\" | chpasswd
  echo \"$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL\" >> /etc/sudoers
"

# 7. Download and configure the startup script back in Termux
echo "Configuring the startup script..."
wget https://raw.githubusercontent.com/LinuxDroidMaster/Termux-Desktops/main/scripts/proot_debian/startxfce4_debian.sh -O debian.sh

# Apply all the sed modifications
sed -i '1a virgl_test_server_android &\nsleep 2' debian.sh
sed -i "s/droidmaster/$USERNAME/g" debian.sh
sed -i 's/env DISPLAY=:0/env DISPLAY=:0 GALLIUM_DRIVER=virpipe MESA_GL_VERSION_OVERRIDE=4.0/g' debian.sh
chmod +x debian.sh

# 8. Final Instructions
echo ""
echo "========================================================================"
echo "                     DEBIAN INSTALLATION COMPLETE                       "
echo "========================================================================"
echo "To start Debian GUI : ./debian.sh"
echo "To start Debian CLI : pd sh debian --user $USERNAME"
echo ""
echo "To stop Debian:"
echo " - In CLI: type 'exit'"
echo " - In GUI: Logout from Debian and exit the Termux session via"
echo "   notifications, OR hold your Termux terminal, click 'More',"
echo "   select 'Kill process', and press Enter."
echo ""
echo "REMEMBER:"
echo "1. Disable child process restrictions in Android Developer Settings."
echo "2. Disable battery optimization for the Termux app."
echo "========================================================================"
