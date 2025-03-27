#!/bin/bash

automatic_rename=$1
curr_dir="$2"
curr_title="$3"
curr_pane_pid=$4
window_zoomed_flag=$5

if [ "$automatic_rename" = "no" ]; then
	echo -n "$curr_title"
	exit 0
fi

user=`whoami`

current_child=""
child_is_su=FALSE

p=${curr_pane_pid}
while [ 1 ]; do
	p=`pgrep -P ${p} | tail -n1`
	if [ -z "$p" ]; then
		break
	fi
	current_child=`ps -p $p -o comm=`
	case "${current_child}" in
		su|sudo)
			child_is_su=TRUE
			;;
		*)
			break
			;;
	esac
done

if [ $child_is_su = TRUE ]; then
	# this happens while su/sudo is prompting for password
	# and still has no children
	if [ -z "$p" ]; then
		child_is_su=FALSE
	else
		curr_dir=`readlink /proc/${p}/cwd 2>/dev/null`
		user=`ps -o uname= -p $p`

		# skip the shell process
		if [[ "$current_child" =~ ^(sh|bash|zsh|dash)$ ]]; then
			p=`pgrep -P ${p} | tail -n1`
		fi

		if [ -n "$p" ]; then
			current_child=`ps -p $p -o comm=`
		else
			current_child=""
		fi
	fi
fi

# while in insert mode, vim changes it's own cwd
# so we have to use parent's cwd
if [ "${current_child}" = "vim" ]; then
	ppid=`grep '^PPid:' /proc/${p}/status | awk '{print $2}'`
	curr_dir=`readlink /proc/${ppid}/cwd 2>/dev/null`
fi

# couldn't find cwd because of permissions
if [ -z "$curr_dir" ]; then
	curr_dir="_"
fi

home_dir=`getent passwd ${user} | cut -d':' -f6`

handle_ssh_command(){
	proc_args=$(ps -p $p -o args=)
	read -ra args_arr <<< "$proc_args"
	for a in "${args_arr[@]}"; do
		if [ "$a" = "ssh" ]; then
			continue
		elif [[ "$a" =~ ^-S ]]; then
			socket=${a/-S/}
		elif [[ "$a" =~ ^[a-zA-Z]+ ]] \
			|| [[ "$a" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
					if [ "$a" = "DUMMY_HOST" ]; then
						echo -n "$socket"
						return 1
					else
						echo -n "ssh $a"
						break
					fi
		fi
	done
}

if [ "$window_zoomed_flag" = 1 ]; then
	echo -n "Z "
fi

if [ $child_is_su = TRUE ]; then
	echo -n "(${user}) "
fi

if [[ "$current_child" =~ ^ssh[x]*$ ]]; then
	ret=$(handle_ssh_command)
	if [ $? -eq 1 ]; then
		# we got a socket file as response
		p=$(pgrep -f -- -oControlPath=$ret)
		ret=$(handle_ssh_command)
		echo -n "$ret"
	else
		echo -n "$ret"
	fi
else
	echo -n $curr_dir | sed -E \
		-e "s|^${home_dir}|~|" \
		-e "s|([^/]{1})[^/]*/|\1/|g" \
		-e "s|/([^/]{1,10})([^/]*)$|/\1@\2@|" \
		-e "s|@[^@]{3,}@|..|g" \
		-e "s|@([^@]*)@$|\1|"

	if [ -n "$current_child" ]; then
		echo -n "|${current_child}"
	fi
fi
