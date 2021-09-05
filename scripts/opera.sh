#!/usr/bin/env bash

# Path to opera installation dir.
OPERA_HOME_DIR=/home/$USER/.opera

# Path to opera version file.
OPERA_HOME_VERSION_FILE=$OPERA_HOME_DIR/.version

# Local Opera version
opera_version_local=0

# Base URL to th opera rpm packages.
OPERA_BASE_URL="https://rpm.opera.com/rpm/"

# Opera build type: stable, developer, beta.
OPERA_BUILD_TYPE=opera_stable

# Path to custom lib dir.
LIB_DIR=/usr/local/

echo -e "\e[33m Opera installation...\e[m"

############################ Step 0. Check local version of Opera.
# TODO: check binary version

if [ -e "$OPERA_HOME_VERSION_FILE" ]; then
  opera_version_local=$(head -n 1 "$OPERA_HOME_VERSION_FILE")
  echo " > Local Opera version: ${opera_version_local}"
fi

########################### Step 1. Getting opera package name and version

echo -e -n "\n 1. Getting opera package name and version.  \e[m"
package_name=$(wget "${OPERA_BASE_URL}" -O - 2>/dev/null | grep -oP "($OPERA_BUILD_TYPE\S*)(?=\")" | tail -n1)

# check if getting package name was successful.
if [ -z "$package_name" ]; then
  echo -e " \e[31m Abort. \e[m"
  echo -e "\e[31m > Cannot get package name. \e[m"
  exit
else
  echo -e "\e[92m Done. \e[m"
fi

# Get the remote version number to compare it with the local version.
opera_version_remote=$(echo "$package_name" | grep -oP "(?<=\-)(\d+(\.\d+){0,5})" | tail -n1)
echo " > Remote Opera version: ${opera_version_remote}"

# Compare local and remote versions. If the first line of the sorted list equals to the remote version,
# it is not needed to install a new package. Exit.
if [ "$(echo -e "$opera_version_remote\n$opera_version_local" | sort -V | head -n 1)" = "$opera_version_remote" ]; then
  echo " > You have the latest version of Opera."
  echo -e " \e[34m Exit. \e[m"
  exit
fi

# clear temporary directory.
tmp_dist="/tmp/${package_name}"
rm -rf "${tmp_dist}"

########################### Step 2. Downloading Opera

echo -e -n "\n 2. Downloading Opera.\t     "
wget "${OPERA_BASE_URL}${package_name}" --progress=dot -O ${tmp_dist} 2>&1 | grep --line-buffered "%" | sed -u -e "s,\.,,g" | awk '{printf("\b\b\b\b%4s", $2)}'

# We should be convinced that the package was downloaded.
if [ -e "$tmp_dist" ]; then
  echo -e "\t \e[92m Done. \e[m \r"
  echo " > Downloaded to: ${tmp_dist}"
else
  echo -e " \e[31m Abort. \e[m"
  echo -e "\e[31m > Cannot find downloaded file in $tmp_dist \e[m"
  exit
fi

########################### Step 3. Installing Opera.
# TODO: check installation
#
echo -e -n "\n 3. Installing Opera."
rpm2cpio "$tmp_dist" | cpio -D "$OPERA_HOME_DIR" -idmv 2>/dev/null
#
if [ -x "$OPERA_HOME_DIR/usr/bin/opera" ]; then
  echo -e "\t \e[92m Done. \e[m \r"
  # Write new version number
  echo "$opera_version_remote" >"$OPERA_HOME_VERSION_FILE"
else
  echo -e " \e[31m Abort. \e[m"
  echo -e "\e[31m > An error occurred while installation.  \e[m"
  exit
fi

# Create desktop entry.
cp "$OPERA_HOME_DIR/usr/share/applications/opera.desktop" "/home/$USER/.local/share/applications/opera.desktop"
# Change execution path.
sed -i "s|^Exec=opera|Exec=${OPERA_HOME_DIR}/usr/bin/opera|" "/home/$USER/.local/share/applications/opera.desktop"
# Remove TryExec line to avoid searching issue.
sed -i "/^TryExec/d" "/home/$USER/.local/share/applications/opera.desktop"
