#!/bin/bash
# Author : Gracjan Grzech ( g.grzech@icloud.com )
# Created On : 16.05.2023
# Last Modified By : Gracjan Grzech ( g.grzech@icloud.com )
# Last Modified On : 28.05.2023
# Version : 2.137
##
# Description : bash tool for supervising the internet search history
#
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

VERSION=2.137
CONFIG_FILENAME="hsv.conf"
REPORT_DIR="../reports/"


DUMP_CACHE_TO_JOURNALCTL='*/5 * * * * pkill -USR1 systemd-resolve'
REDIRECT_CACHE_TO_LOG="*/5 * * * * sh -c 'journalctl -o short-iso --since \"5 minutes ago\" -u systemd-resolved  >> /var/log/hsv.log'"
REPORT_CONSTRUCTION_CRONJOB="1 7 HSVreport gracjangrzech/IdeaProjects/HistorySupervisor/src/reportConstructor.sh 2>&1"

parseArguments () {
  local OPTIND options
  while getopts ":hv" options; do
    case $options in
      v)
        echoVersion
        exit 0
        ;;
      h)
        echoHelp
        exit 0
        ;;
      *)
        echoInvalidArgument
        ;;
    esac
  done
  shift $((OPTIND-1))
}

echoHelp () {
  printf "History supervisor is a program used to monitor the internet search history.\nAvailable flags:\n -v - check the current version\n -h - display this message\nLaunching the program without flags will run the gui\n"
}

echoVersion () {
  echo "History Supervisor - Version: $VERSION"
}

echoInvalidArgument () {
  echo "Invalid argument, refer to -h for more info"
}

showMainMenu() {
  local mainMenu
  mainMenu=$(zenity --width=300 --height=400 --list --title="HistorySupervisor" \
    --column="Options" \
    "Add New Keyword" \
    "Load Keywords From File" \
    "Remove Keyword" \
    "Wipe all Keywords" \
    "Start Supervision" \
    "Stop Supervision" \
    "List Reports" \
    "Exit")

  case $mainMenu in
    "Add New Keyword")
      add_new_keyword
      ;;
    "Load Keywords From File")
      loadKeywordsFromFile
      ;;
    "Remove Keyword")
      removeKeyword
      ;;
    "Wipe all Keywords")
      wipeKeywords
      ;;
    "Start Supervision")
      supervise
      ;;
    "Stop Supervision")
      stopSupervision
      ;;
    "List Reports")
      listReports
      ;;
    "Exit")
      exit 0
      ;;
    *)
      exit 0
      ;;
  esac
}

showSubmenu() {
  local input
  input=$(zenity --entry --title="$1" --text="$2")
  echo "$input"
}

add_new_keyword() {
  local keywords
  keywords=$(showSubmenu "Add keyword/s" "Enter keywords")
  if ! [[ -z $keywords ]]; then
    for keyword in $keywords; do
      grep -qF "$keyword" $CONFIG_FILENAME || echo "$keyword" >> $CONFIG_FILENAME
    done
    zenity --info --text="Keyword/s $keywords have been added successfully."
  fi

  showMainMenu
}

loadKeywordsFromFile() {
  local filepath
  filepath=$(showSubmenu "Load Keywords" "Enter Path")
  if [[ -n $filepath ]]; then
    cp "$filepath" $CONFIG_FILENAME
    echo "" >> $CONFIG_FILENAME
  fi

  showMainMenu
}

removeKeyword() {
  local keywords
  keywords=$(showSubmenu "Remove keyword" "Enter keyword")
  if [[ -n $keywords ]]; then
    for keyword in $keywords; do
      sed -i "/$keyword/d" $CONFIG_FILENAME
    done
  fi

  showMainMenu
}

wipeKeywords() {
  truncate -s 0 $CONFIG_FILENAME
  showMainMenu
}


listReports() {
  local fileMenu listOptions
  listOptions=($(ls $REPORT_DIR))
  fileMenu=$(zenity --width=300 --height=400 --list --column="Reports" "${listOptions[@]}")
  zenity --text-info --width=450 --height=400 --filename="$REPORT_DIR$fileMenu"

  showMainMenu
}

supervise() {
  startRecordingCache
  startProducingReports
  showMainMenu
}

startRecordingCache() {
  local tmpFile
  tmpFile=$(mktemp);
  crontab -l > "$tmpFile" 2> /dev/null
  crontab -l | grep -qF -- "$DUMP_CACHE_TO_JOURNALCTL" || echo "$DUMP_CACHE_TO_JOURNALCTL" >> "$tmpFile" 2>/dev/null
  crontab -l | grep -qF -- "$REDIRECT_CACHE_TO_LOG" || echo "$REDIRECT_CACHE_TO_LOG" >> "$tmpFile" 2>/dev/null
  crontab -r
  crontab "$tmpFile"
  rm "${tmpFile}"
}

startProducingReports() {
  local tmpFile
  tmpFile=$(mktemp);
  cat /etc/anacrontab | grep -qF -- "$REPORT_CONSTRUCTION_CRONJOB" || echo "$REPORT_CONSTRUCTION_CRONJOB" | sponge -a /etc/anacrontab
  anacron -T
  rm "${tmpFile}"
}

stopSupervision() {
  clearCrontab
  clearAnacron
  showMainMenu
}

clearCrontab() {
  local tmpFile
  tmpFile=$(mktemp)
  crontab -l | grep -vF "$DUMP_CACHE_TO_JOURNALCTL" | crontab -
  crontab -l | grep -vF "$REDIRECT_CACHE_TO_LOG" | crontab -
}

clearAnacron() {
  cat /etc/anacrontab | grep -vF "$REPORT_CONSTRUCTION_CRONJOB" | sponge /etc/anacrontab
}


parseArguments "$@"
showMainMenu
