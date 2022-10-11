#!/usr/bin/env bash

if [ -z "$BASH" ]; then
	echo "dt-env-common.sh: This is not loading in bash. Skipping."
	return
fi

# set HOME just in case it wasn't set properly
export HOME=$(getent passwd $(whoami) | cut -d':' -f6)

# to avoid less on every output
export SYSTEMD_PAGER=''

if [ -f /usr/bin/vi ]; then
	export EDITOR=vi
fi

## Colors
function printRed { echo -e "\e[0;31m${1}\e[0m"; }
export -f printRed
function printGreen { echo -e "\e[0;32m${1}\e[0m"; }
export -f printGreen
function printCyan { echo -e "\e[0;36m${1}\e[0m"; }
export -f printCyan
function printBlue { echo -e "\e[0;34m${1}\e[0m"; }
export -f printBlue
function printPurple { echo -e "\e[0;35m${1}\e[0m"; }
export -f printPurple
function printBoldRed { echo -e "\e[1;31m${1}\e[0m"; }
export -f printBoldRed
function printBoldGreen { echo -e "\e[1;32m${1}\e[0m"; }
export -f printBoldGreen
function printBoldCyan { echo -e "\e[1;36m${1}\e[0m"; }
export -f printBoldCyan
function printBoldBlue { echo -e "\e[1;34m${1}\e[0m"; }
export -f printBoldBlue
function printBoldPurple { echo -e "\e[1;35m${1}\e[0m"; }
export -f printBoldPurple
## Colors

# after this line only stuff for interactive shell should be defined
! [[ "$-" =~ i ]] && return

# for uninitialized terminals
if [ -z "$TERM" ] || [ "$TERM" = "dumb" ]; then
	export TERM=xterm
fi

PS1='[$([ $? -eq 0 ] && (echo -e "\[\e[32m\]\xe2\x9c\x94") || (echo -e "\[\e[31m\]\xe2\x9c\x98"))\[\e[0m\]]\[\033]0;\u@\h:\w\007\][$([ \u = root ] && echo -e "\[\033[01;31m\]" || echo -e "\[\033[01;32m\]")\u@\h\[\033[00m\]]\[\033[01;34m\] \w \[\033[00m\]$(k=$(kubectl config current-context 2>/dev/null | cut -d/ -f2); [ -n "$k" ] && echo "(\[\033[0;33m\]k:$k\[\033[00m\]) ")$(g="`git symbolic-ref --short HEAD 2>/dev/null`"; [ -n "$g" ] && echo "(g:$g) ")\[\033[01;34m\]\$\[\033[00m\]\[\033[00m\] '

# some basic ones because debian doesn't have them
alias egrep='egrep --colour=auto'
alias fgrep='fgrep --colour=auto'
alias grep='grep --colour=auto'
alias ls='ls --color=auto'

alias ping="ping -c 5"
alias top="top -c"
alias lfp="pgrep -aif"
alias systemctl="systemctl -l"

alias psmem='ps -eo pid,rss,args | sort -b -k2,2n | cut -c -`tput cols`'

# Capture the current pane into a vim buffer
alias tmux-cap='tmux capture-pane -p -S- -E- | vim -c "setlocal filetype=none buftype=nofile nolist | normal! zRG" -'


# use a custom config loader that will load the system and then
# our own tigrc
if [ -f /etc/tigrc-custom ]; then
	export TIGRC_SYSTEM=/etc/tigrc-custom
fi
# wrapper function to catch reloading tig with params
function tig {
	/usr/bin/tig $@
	while [ -f ~/.tig_param ]; do
		p=$(cat ~/.tig_param)
		rm ~/.tig_param
		/usr/bin/tig $p
	done
}

function xuniq {
	awk '!x[$0]++'
}
export -f xuniq

function xopen {
	gio open -- "$1" >/dev/null 2>&1
}

function whoswap {
	for f in /proc/*/status; do \
		awk '/^Pid|^VmSwap|^Name/{printf $2" "$3}END{print ""}' $f; \
	done \
	| sort -k3 -n \
	| awk '{if($3>0){print $2"|"$1"|"$3" kB"}}' \
	| column -s '|' -t
}

function hdl {
	which openssl >/dev/null || return 1
	local f="${HOME}/Downloads/$(ls -1t ${HOME}/Downloads/ | head -n1)"
	local d=${HOME}/tmp/$(openssl rand 8 | xxd -ps -c 256)
	echo -e "\nHandling '$f'\n"
	local cmd=""
	case "$f" in
		*.zip) cmd="unzip";;
		*.tar|*.tar.gz|*.tar.bz2|tar.xz|*.tbz|*.tgz) cmd="tar xpf";;
		*.rar) cmd="unrar x";;
		*) echo -e "\nDon't know how to handle '$f'\n"; return 1;;
	esac
	mkdir -p "$d"; cd "$d"
	$cmd "$f" >/dev/null \
		&& echo -e "\nRemoving '$f'\n" && rm "$f" && ls -l
}

function mmv {
	if [ $# -eq 0 ]; then
		echo "Need files to rename"
		return 1
	fi
	(
	echo $'# execute with \':%!bash\''
	echo $'# replace only in the new filename block: \'%s/\\t\\t.*\zsSOMETEXT/NEWTEXT/\''
	ls -1d --quoting-style=shell "$@" | sed 's/^\(.*\)$/mv -nT \1\t\1/' \
		| column -t -s $'\t' -o $'\t\t'
	) | vim - -c 'setlocal filetype=bash buftype=nofile nolist'
}

function _dt_expand_homedir_tilde {
	(
	set -e
	set -u
	p="$1"
	if [[ "$p" =~ ^~ ]]; then
		u=`echo "$p" | sed 's|^~\([a-z0-9_-]*\)/.*|\1|'`
		if [ -z "$u" ]; then
			u=`whoami`
		fi

		h=$(set -o pipefail; getent passwd "$u" | cut -d: -f6) || exit 1
		p=`echo "$p" | sed "s|^~[a-z0-9_-]*/|${h}/|"`
	fi
	echo $p
	) || echo $1
}

function _dt_smart_readline_ls {
	local ls_param=lAhtr

	local partial_line=`echo "${TEMP_READLINE_LINE:0:${TEMP_READLINE_POINT}}" | sed "s/\s\+$/A/"`

	local param_arr
	read -a param_arr <<< "${partial_line}"

	if [[ ${#param_arr[@]} -gt 0 ]] && [[ "${param_arr[-1]}" =~ /$ ]]; then
		local parsed_path=`_dt_expand_homedir_tilde "${param_arr[-1]}"`
		ls -${ls_param} "$parsed_path"
	else
		ls -${ls_param}
	fi
}

# Bind Ctrl-e to delete to end of current word
bind '"\C-e": shell-kill-word'

# Bind Up and Down arrows to history search
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# maintain state
bind -x '"\200": TEMP_READLINE_LINE=$READLINE_LINE; TEMP_READLINE_POINT=$READLINE_POINT'
bind -x '"\201": READLINE_LINE=$TEMP_READLINE_LINE; READLINE_POINT=$TEMP_READLINE_POINT; unset TEMP_READLINE_POINT; unset TEMP_READLINE_LINE'
# Bind Alt+u to got up in directory tree
bind -x '"\205": "cd .."'
bind '"\eu":"\200\C-a\C-k\205\C-m\201"'
# Bind Alt+l to directory listing
bind -x '"\206": _dt_smart_readline_ls'
bind '"\el":"\200\C-a\C-k\C-m\206\201"'
# Bind Alt+k to directory listing command start
bind -x '"\207":READLINE_LINE=""'
bind '"\ek":"\207ls -lAhtr "'
# Bind Alt+b to go back in directory history
bind -x '"\208":"popd &>/dev/null; popd &>/dev/null"'
bind '"\eb":"\200\C-a\C-k\208\C-m\201"'
# Bind Alt+c to toggle comment on current command and hit enter
# if the line was commented
bind -x '"\209": if [[ "$READLINE_LINE" =~ ^# ]]; then READLINE_LINE="${READLINE_LINE:1}"; let READLINE_POINT--; bind "\"\210\":\"\""; else READLINE_LINE="#${READLINE_LINE}"; bind "\"\210\":\"\n\""; fi'
bind '"\ec":"\209\210"'

: >> ~/.bash_init_lock #create a file if it doesn't exist
{
flock 3 #lock file by filedescriptor

if [ -f ~/.bash_history_extended ]; then
	cat ~/.bash_history_extended | grep -v '^#' | tac | awk '!x[$0]++' | tac > ~/.tmp_history
	cat ~/.tmp_history > ~/.bash_history_extended
	rm ~/.tmp_history
	history -c
	history -r
fi
} 3<~/.bash_init_lock

HISTCONTROL="ignorespace"
HISTTIMEFORMAT="%s "
HISTFILESIZE=1000000
HISTSIZE=1000000
HISTFILE=~/.bash_history_extended

function run_time_format() {
	if [ $1 -lt 86400 ]; then
		date -d@${1} -u '+%Hh:%Mm:%Ss'
	else 
		echo "$(($1/86400)) days $(date -d@$(($1%86400)) -u '+%Hh:%Mm:%Ss')"
	fi
}
function notifen (){
	export DO_LONG_COMMAND_NOTIFICATION=1
}
function notifdis (){
	unset DO_LONG_COMMAND_NOTIFICATION
}
last_comm_num=0
function long_command_notify () {
	END=$(date '+%s')
	LAST_COMM=$(history 1)
	if [ -z "$LAST_COMM" ]; then
		last_comm_num=-1
		return
	fi
	START=$(awk '{print $2}' <<<"$LAST_COMM")
	# check that a timestamp exists (avoid ??command lines)
	if ! [[ "$START" =~ ^[0-9]+$ ]] ; then
		last_comm_num=-1
		return
	fi
	START_TIME=$(date -d"@$START" '+%F %T')
	COMM=$(awk '{print $3}' <<<"$LAST_COMM")

	curr_command_num=$(awk '{print $1}' <<<"$LAST_COMM")
	if [ $last_comm_num -eq 0 ]; then
		last_comm_num=$curr_command_num
	fi
	[ $curr_command_num -eq $last_comm_num ] && return
	last_comm_num=$curr_command_num

	DIFF=$((END - START))
	DIFF_FORMATTED=$(run_time_format $DIFF)

	if [ $DIFF -ge 10 ]; then
		echo
		printBoldPurple ">>> '$COMM' started at $START_TIME, finished in $DIFF_FORMATTED"

		if [ -n "$DO_LONG_COMMAND_NOTIFICATION" ]; then
			zenity --info --no-wrap --icon-name=dialog-information --text "'$COMM' took\n$DIFF_FORMATTED\nto execute" &
		fi
	fi
}

function _prompt_pre {
	long_command_notify
	history -a

	# Store current directory if it's not already last in stack
	if [ "`dirs -l -p | sed -n '2p;3q'`" != "$PWD" ]; then
		builtin pushd -n "$PWD" >/dev/null
	fi
}

[ -n "$PROMPT_COMMAND" ] && PROMPT_COMMAND+=";"
PROMPT_COMMAND+="_prompt_pre"

_dt_temp_prev_compl_cmd=""
function _dt_fzf_compl {
	local c=$(IFS=' '; read -ra s <<< "$READLINE_LINE"; echo ${s[0]})
	if [ "$1" = "set" ]; then
		_dt_temp_prev_compl_cmd=$(complete -p "$c" 2>/dev/null)
		local cmd="complete -F _fzf_path_completion -o default -o bashdefault $c"
	elif [ "$1" = "unset" ]; then
		local cmd="$_dt_temp_prev_compl_cmd"
	else
		return
	fi
	if ! [[ "$_dt_temp_prev_compl_cmd" =~ _fzf_ ]]; then
		complete -r "$c" &>/dev/null
		$cmd
	fi
}

__dt_fzf_bash_comp=""
if [ -f /usr/share/doc/fzf/examples/completion.bash ]; then
	__dt_fzf_bash_comp=/usr/share/doc/fzf/examples/completion.bash
elif [ -f /usr/share/bash-completion/completions/fzf ]; then
	__dt_fzf_bash_comp=/usr/share/bash-completion/completions/fzf
fi
if [ -n "$__dt_fzf_bash_comp" ]; then
	source $__dt_fzf_bash_comp
	bind -x '"\220":"_dt_fzf_compl set"'
	bind -x '"\221":"_dt_fzf_compl unset"'
	bind '"\ef":"\220**\t\221"'
fi

_dt_term_socket_ssh() {
	ssh -oControlPath=$1 -O exit DUMMY_HOST
}
function sshx {
	local t=$(mktemp -u --tmpdir ssh.sock.XXXXXXXXXX)
	local f="~/clip"
	ssh -f -oControlMaster=yes -oControlPath=$t $@ tail\ -f\ /dev/null \
		&> >(grep -v '^mux_master_process_new_session: tcgetattr: Inappropriate ioctl for device') \
		|| return 1
	ssh -S$t DUMMY_HOST "bash -c 'if ! [ -p $f ]; then mkfifo $f; fi'" \
		|| { _dt_term_socket_ssh $t; return 1; }
	(
	set -e
	set -o pipefail
	while [ 1 ]; do
		ssh -S$t -tt DUMMY_HOST "cat $f" 2>/dev/null | xclip -selection clipboard
		# ioctl error is thrown by this command in some versions of
		# ssh client because we're forcing here a PTY in order to keep hold of
		# the remote cat command. This prevents remote having cat processes
		# sticking around long after the session is closed. The issue is
		# that the ssh command of ControlMaster is running in the background
		# and therefore has the tcgetattr() call failing,
		# not getting terminal properties.
	done &
	)
	ssh -S$t -t DUMMY_HOST "tmux attach -t remote || tmux new -s remote \; split-window -v -p 30 \; send-keys 'htop || top -c' C-m\; select-pane -t 0" \
		|| { _dt_term_socket_ssh $t; return 1; }
	ssh -S$t DUMMY_HOST "command rm $f"
	_dt_term_socket_ssh $t
}

function _dt_write_to_clipboard {
	local v=$(cat -)
	local v_nonewline="${v//[$'\t\r\n']}"
	if [ ${#v_nonewline} -gt 20 ]; then
		local v_trunc="${v_nonewline:0:20}.."
	else
		local v_trunc="${v_nonewline}"
	fi
	local remote_clipboard_file="$(getent passwd $(whoami) | cut -d':' -f6)/clip"
	if [ -p $remote_clipboard_file ] \
		&& dd oflag=nonblock conv=notrunc,nocreat count=0 of=$remote_clipboard_file 2>/dev/null; then
		echo -n "$v" > $remote_clipboard_file
		echo "Wrote '$v_trunc' to remote clipboard"
	else
		(
		set -e
		exec 2>&1
		echo -n "$v" | xclip -selection clipboard
		echo "Wrote '$v_trunc' to local clipboard"
		)
	fi
}
export -f _dt_write_to_clipboard

# This function is used in the injected environment to set git settings via env
# variables when the ~/.gitconfig is disabled with a:
# export GIT_CONFIG_GLOBAL=
function __dt_set_git_env_conf {
	if [ -z "$GIT_CONFIG_COUNT" ]; then
		export GIT_CONFIG_COUNT=0
	fi

	export GIT_CONFIG_KEY_${GIT_CONFIG_COUNT}="$1"
	export GIT_CONFIG_VALUE_${GIT_CONFIG_COUNT}="$2"

	let "GIT_CONFIG_COUNT++"
	export GIT_CONFIG_COUNT
}

# cd HOME for environments that it's not done by default
if [ "$PWD" = "/" ]; then
	command cd
fi
