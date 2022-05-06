#!/bin/bash

pkgs=/root/pkgs.txt

action="$1"
shift

case "$action" in
	install)
		apt-get install -V $@
		if [ $? -eq 0 ]; then
			for p in "$@"; do
				echo ${p} >> ${pkgs}
			done
		fi
		apt-get clean
		;;
	list)
		dpkg -l \
			| grep '^ii' \
			| awk '{print $2}' \
			| while read p; do \
			if grep -q "^${p}$" ${pkgs}; then \
				echo $p; \
				fi; \
			done
		;;
	*)
		echo -e "\nUse command: install|list\n"
		;;
esac
