#!/usr/bin/env bash

AVAILABLE_APPS=("Opera" "Brave" "VSCode")

# helper function.
has_needed_packages() {
  # check for rpm2cpio needed to unpack rpm
  if ! [ -x "$(command -v rpm2cpio)" ]; then
    echo -e "\e[34m Package rpm2cpio is needed to be installed. Install?"

    select answer in "Yes" "No"; do
      if [ $answer == "Yes" ]; then
        sudo swupd bundle-add package-utils
        return 0
      else
        return 1
      fi
    done

  else
    return 0
  fi

}

echo "What would you like to install?"

select app_name in "${AVAILABLE_APPS[@]}"; do
  script_path="./scripts/${app_name,,}.sh"
  echo "${app_name}"

  # check for script existence.
  if ! [ -e "$script_path" ]; then
    echo -e "\e[31m Sorry! $app_name script not found.\e[m"
    break
  fi

  # check for existence of system commands.
  if ! has_needed_packages; then
    echo -e "\e[31m Needed packages were not installed. Abort. \e[m"
    break
  fi

  # run inner script for selected application.
  bash $script_path
  break

done