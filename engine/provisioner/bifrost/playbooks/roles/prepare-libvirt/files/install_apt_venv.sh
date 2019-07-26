#!/usr/bin/env bash
VENV_SITE_PACKAGES_DIR="$1/lib/python*/site-packages"
LOCAL_USER="$2"

# Get python-apt and install into venv
cd /tmp
echo "Downloading python-apt using apt"
apt download python-apt

echo "Extracting python-apt..."
dpkg -x python-apt_*.deb python-apt
chown -R $LOCAL_USER:$LOCAL_USER /tmp/python-apt/usr/lib/python*/dist-packages/*

echo "Moving python-apt libraries into $VENV_SITE_PACKAGES_DIR"
mv /tmp/python-apt/usr/lib/python*/dist-packages/* $VENV_SITE_PACKAGES_DIR
cd $VENV_SITE_PACKAGES_DIR
mv apt_pkg.*.so apt_pkg.so
mv apt_inst.*.so apt_inst.so

echo "Removing downloaded python-apt in /tmp"
rm -rf /tmp/python-apt*
