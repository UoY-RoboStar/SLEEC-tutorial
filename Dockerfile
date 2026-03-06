# Use a stable Ubuntu base image
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential tools, X11/GUI dependencies, and clipboard managers
RUN apt-get update && apt-get install -y \
    wget \
    tar \
    git \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libfreetype6 \
    fontconfig \
    sudo \
    tigervnc-standalone-server \
    x11-xserver-utils \
    novnc websockify \
    xfce4 xfce4-terminal \
    unzip \
    python3-pip \
    python3-tk \
    idle3 \
    libgtk-3-0 \
    libsecret-1-0 \
    libcanberra-gtk3-module \
    libswt-gtk-4-jni \
    libtinfo5 \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Prevent XFCE from locking the screen and asking for a password
RUN apt-get remove -y xfce4-screensaver light-locker xscreensaver xfce4-power-manager || true \
    && apt-get autoremove -y

# Fix for FDR later
RUN add-apt-repository ppa:linuxuprising/libpng12 && \
    apt-get update && \
    apt-get install -y libpng12-0 && \
    rm -rf /var/lib/apt/lists/*

# Fix for FDR's certificates
RUN mkdir -p /etc/pki/tls/certs/ && ln -s /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt

# Add FDR's apt repo (removed sudo as we are already root)
RUN echo "deb http://dl.cocotec.io/fdr/debian/ fdr release" > /etc/apt/sources.list.d/fdr.list \
    && wget -qO - http://dl.cocotec.io/fdr/linux_deploy.key | apt-key add -

# Set environment variables for the specific version
ENV IDEA_VERSION=2021.3.3
ENV IDEA_BUILD=ideaIC-${IDEA_VERSION}
ENV IDEA_URL=https://download.jetbrains.com/idea/${IDEA_BUILD}.tar.gz

# Download and extract IntelliJ IDEA to /opt/idea
RUN wget -q -O /tmp/idea.tar.gz $IDEA_URL \
    && mkdir -p /opt/idea \
    && tar -xzf /tmp/idea.tar.gz --strip-components=1 -C /opt/idea \
    && rm /tmp/idea.tar.gz

# We create a non-root user named 'sleec' with passwordless sudo
RUN useradd -ms /bin/bash sleec \
    && echo "sleec ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Setup VNC/X11 Startup Script (Using cat EOF for cleaner syntax)
RUN cat << 'EOF' > /usr/local/bin/start-workspace.sh
#!/bin/bash
export DISPLAY=:0

# Clean up any leftover lock files from previous runs
rm -f /tmp/.X0-lock /tmp/.X11-unix/X0

# 1. Start TigerVNC
Xvnc :0 -geometry 1280x800 -depth 24 -SecurityTypes None -localhost no &

# Wait briefly for the X server to stand up before applying X11 settings
sleep 2

# 2. Disable X11 screen blanking and power management
xset s off
xset s noblank
xset -dpms

# 4. Remap Mac CMD to Linux CTRL
xmodmap -e "clear control"
xmodmap -e "clear mod4"
xmodmap -e "keycode 133 = Control_L"
xmodmap -e "keycode 37 = Super_L"
xmodmap -e "add control = Control_L Control_R"
xmodmap -e "add mod4 = Super_L Super_R"

# 5. Start the noVNC web bridge
websockify --web=/usr/share/novnc/ 8080 localhost:5900 &

# 6. Start XFCE in the foreground (This keeps the container running)
exec startxfce4
EOF

# Create an index.html that auto-redirects to VNC with remote resizing and auto-connect enabled
RUN echo '<meta http-equiv="refresh" content="0; url=vnc.html?autoconnect=true&resize=remote">' > /usr/share/novnc/index.html

# Make start-workspace executable
RUN chmod +x /usr/local/bin/start-workspace.sh

# Install sleec Plugin for IntelliJ
RUN wget -O sleec-plugin.zip "https://plugins.jetbrains.com/pluginManager/?action=download&id=com.kevink.SleecLanguageExtension&build=213.0" \
    && unzip sleec-plugin.zip -d /opt/idea/plugins/ \
    && rm sleec-plugin.zip

# Download and Extract SLEEC-TK
RUN wget https://github.com/UoY-RoboStar/SLEEC-TK/releases/latest/download/robostar.sleectk.product-linux.gtk.x86_64.tar.gz -O /tmp/sleec.tar.gz && \
    mkdir -p /opt/sleec-tk && \
    tar -xzf /tmp/sleec.tar.gz -C /opt/sleec-tk && \
    rm /tmp/sleec.tar.gz

# Fix ownership
RUN chown -R sleec:sleec /opt/idea /opt/sleec-tk

# Switch to the sleec user
USER sleec
ENV HOME=/home/sleec
WORKDIR $HOME

# Add the local user bin directory to the PATH
ENV PATH="$HOME/.local/bin:$PATH"

# Upgrade the core Python build tools first
RUN pip install --no-cache-dir --upgrade pip setuptools wheel

# Install pip dependencies.
RUN pip install --no-cache-dir z3-solver==4.12.2.0 pysmt ordered-set textx termcolor

# Create Desktop Entries
RUN mkdir -p /home/sleec/Desktop && \
    echo "[Desktop Entry]\n\
Version=1.0\n\
Type=Application\n\
Name=IntelliJ IDEA\n\
Icon=/opt/idea/bin/idea.png\n\
Exec=/opt/idea/bin/idea.sh\n\
Path=/home/sleec\n\
Comment=The Drive to Develop\n\
Categories=Development;IDE;\n\
Terminal=false" > /home/sleec/Desktop/intellij.desktop && \
    echo "[Desktop Entry]\n\
Version=1.0\n\
Type=Application\n\
Name=SLEEC-TK\n\
Comment=SLEEC ToolKit\n\
Exec=/opt/sleec-tk/eclipse -data /home/sleec/eclipse-workspace\n\
Icon=/opt/sleec-tk/icon.xpm\n\
Path=/opt/sleec-tk\n\
Terminal=false\n\
Categories=Development;IDE;" > /home/sleec/Desktop/sleec.desktop && \
    echo "[Desktop Entry]\n\
Version=1.0\n\
Type=Application\n\
Name=FDR4 (Launch or Install)\n\
Comment=Click to run FDR or install it if missing\n\
Exec=xfce4-terminal --title='FDR4 Manager' -e \"bash -c 'if [ -f /usr/bin/fdr4 ]; then /usr/bin/fdr4; else echo \\\"FDR not found. Starting installation...\\\"; sudo apt update && sudo apt install -y fdr; echo \\\"Installation complete! Press Enter to launch FDR...\\\"; read; /usr/bin/fdr4; fi'\"\n\
Icon=fdr4\n\
Terminal=false\n\
Categories=Development;Science;IDE;" > /home/sleec/Desktop/fdr.desktop && \
    chmod +x /home/sleec/Desktop/*.desktop && \
    chown -R sleec:sleec /home/sleec/Desktop /opt/sleec-tk

# Copy sample SLEEC-TK project
RUN mkdir -p /home/sleec/git/SLEEC-TK && mkdir -p /home/sleec/eclipse-workspace && git clone -b tutorial https://github.com/UoY-RoboStar/SLEEC-TK /home/sleec/git/SLEEC-TK

# Add SLEEC-TK Eclipse .metadata to workspace
ADD --chown=sleec:sleec ./sleec-tk/metadata.tar.gz /home/sleec/eclipse-workspace/

# Expose the web port
EXPOSE 8080

# Set the entrypoint to our custom script
CMD ["/usr/local/bin/start-workspace.sh"]