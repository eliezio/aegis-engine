#!/usr/bin/env bash
VENV_SITE_PACKAGES_DIR="$1/lib/python3*/site-packages"
LOCAL_USER="$2"

# Get python3-apt and install into venv
cd /tmp
echo "Downloading python3-apt using apt"
apt download python3-apt

echo "Extracting python3-apt..."
dpkg -x python3-apt_*.deb python3-apt
chown -R $LOCAL_USER:$LOCAL_USER /tmp/python3-apt/usr/lib/python3*/dist-packages/*

echo "Moving python3-apt libraries into $VENV_SITE_PACKAGES_DIR"
mv /tmp/python3-apt/usr/lib/python3*/dist-packages/* $VENV_SITE_PACKAGES_DIR
cd $VENV_SITE_PACKAGES_DIR
mv apt_pkg.*.so apt_pkg.so
mv apt_inst.*.so apt_inst.so

echo "Removing downloaded python3-apt in /tmp"
rm -rf /tmp/python3-apt*
