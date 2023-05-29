#!/bin/bash
# Author : Gracjan Grzech ( g.grzech@icloud.com )
# Created On : 16.05.2023
# Last Modified By : Gracjan Grzech ( g.grzech@icloud.com )
# Last Modified On : 28.05.2023
# Version : 2.137
##
# Description : bash tool for constructing reports for the History Supervisor script
#
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

CONFIG_FILENAME="/home/gracjangrzech/IdeaProjects/HistorySupervisor/src/hsv.conf"
REPORT_DIR="/home/gracjangrzech/IdeaProjects/HistorySupervisor/reports/"


readarray -t keywords < $CONFIG_FILENAME
sed -i '/^--/d' /var/log/hsv.log
while [ -s /var/log/hsv.log ]; do
  filename="$(head -n 1 /var/log/hsv.log | cut -d " " -f 1 | sed 's/T.*//')"
  if [[ -z "$filename" ]]; then
    exit 0
  fi
  tmp=$(mktemp)
  for keyword in "${keywords[@]}"; do
      grep "$filename" /var/log/hsv.log | grep -i "$keyword" | cut -d " " -f 1,12 | head -1 >> "$REPORT_DIR$filename"
  done
  grep -v "$filename" /var/log/hsv.log > "$tmp"
  cat "$tmp" > /var/log/hsv.log
  if ! [[ -s "$REPORT_DIR$filename" ]]; then
    rm "$REPORT_DIR$filename"
  fi
done


