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

function set_dbus_session_var {
	eval $(cat /proc/$(pgrep -x mate-session)/environ | tr '\0' '\n' \
		| grep '^DBUS_SESSION_BUS_ADDRESS=' \
		| sed 's/^\([^=]\+\)=\(.*\)$/\1="\2"/')
}
export -f set_dbus_session_var

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
	(
	set_dbus_session_var
	if [ $# -gt 0 ]; then
		p=("$@")
	else
		p=""
	fi
	gio open -- "${p[@]}" &>/dev/null
	)
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
	local ls_param=$1

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

# configure vi/emacs prompt
bind 'set vi-cmd-mode-string "N"'
bind 'set vi-ins-mode-string "I"'
bind 'set emacs-mode-string ""'
bind 'set show-mode-in-prompt on'

# vi mode bindings
bind -m vi-command '"\e": emacs-editing-mode'
bind -m vi-command '"\t": emacs-editing-mode'
bind -m vi-command '"\em": emacs-editing-mode'
bind -m vi-insert '"\t": vi-movement-mode'
bind -m vi-insert '"\em": emacs-editing-mode'

# Bind Ctrl-e to delete to end of current word
bind '"\C-e": shell-kill-word'
# Bind Alt+w to remove last portion of a path
bind '"\ew":"\e[D\e\C-]/\e[C\e\C-d"'

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
bind -x '"\206": _dt_smart_readline_ls lAhtr'
bind -x '"\207": _dt_smart_readline_ls lh'
bind '"\el":"\200\C-a\C-k\C-m\206\201"'
bind '"\el\el":"\200\C-a\C-k\C-m\207\201"'
# Bind Alt+k to directory listing command start
bind '"\ek":"\C-a\C-kls -lAhtr "'
bind '"\ek\ek":"\C-a\C-kls -lh "'
# Bind Alt+b to go back in directory history
bind -x '"\208":"popd &>/dev/null; popd &>/dev/null"'
bind '"\eb":"\200\C-a\C-k\208\C-m\201"'
# Bind Alt+c to toggle comment on current command and hit enter
# if the line was commented
bind -x '"\209": if [[ "$READLINE_LINE" =~ ^# ]]; then READLINE_LINE="${READLINE_LINE:1}"; let READLINE_POINT--; bind "\"\210\":\"\""; else READLINE_LINE="#${READLINE_LINE}"; bind "\"\210\":\"\n\""; fi'
bind '"\ec":"\209\210"'
# Re-bind Ctrl-w to remove actual full words including spaces.
# Use unix-word-rubout (the original C-w) only in case we are about to
# remove a special char because shell-backward-kill-word doesn't consider it a word.
stty werase undef
bind -x '"\211": if [[ "${READLINE_LINE:0:${READLINE_POINT}}" =~ [[:space:]]+(>|<|\|)[[:space:]]*$ ]]; then bind "\"\212\": unix-word-rubout"; else bind "\"\212\": shell-backward-kill-word"; fi'
bind '"\C-w": "\211\212"'
# re-bind Ctrl-(Left/Right) to better handle spaces and slashes
bind -x '"\213": TEMP_JUMP_POINTS=`echo "$READLINE_LINE" | sed "s/\\\\\ /%%/g" | grep -bo "[^$/={@:[:space:]]\+" | cut -d: -f1; echo ${#READLINE_LINE}`'
bind -x '"\214": unset TEMP_JUMP_POINTS'
bind -x '"\215": while read p; do if [ $p -lt $READLINE_POINT ]; then READLINE_POINT=$p; break; fi; done <<<$(echo "$TEMP_JUMP_POINTS" | tac)'
bind -x '"\216": while read p; do if [ $p -gt $READLINE_POINT ]; then READLINE_POINT=$p; break; fi; done <<<$(echo "$TEMP_JUMP_POINTS")'
bind '"\e[1;5D": "\213\215\214"'
bind '"\e[1;5C": "\213\216\214"'
# switch to vi mode using Alt-m (immediately press Tab to switch to normal mode)
bind '"\217": vi-editing-mode'
bind '"\em": "\217\tl"'
# Alt+p to remove everything but the last param and add space
bind '"\ep": "\e[F\e\C-b\C-x\C-? \e[D"'
# Alt+o to remove everything but the last param and add space
bind -x '"\218": printf -v TEMP_OLDPWD_ESCAPED "%q" "${OLDPWD}"; READLINE_LINE="${READLINE_LINE:0:${READLINE_POINT}}${TEMP_OLDPWD_ESCAPED}/ ${READLINE_LINE:${READLINE_POINT}}"; let "READLINE_POINT += ${#TEMP_OLDPWD_ESCAPED} + 1"; unset TEMP_OLDPWD_ESCAPED'
bind '"\eo": "\218"'


__dt_bash_init_lock_file=~/.bash_init_lock
: >> $__dt_bash_init_lock_file #create a file if it doesn't exist
{
	flock 3 #lock file by filedescriptor

	if [ -f ~/.bash_history_extended ]; then
		cat ~/.bash_history_extended | grep -v '^#' | tac | awk '!x[$0]++' | tac > ~/.tmp_history
		cat ~/.tmp_history > ~/.bash_history_extended
		rm ~/.tmp_history
		history -c
		history -r
	fi
} 3<$__dt_bash_init_lock_file

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

# use hosts completion for sshx
if [ "$(type -t _known_hosts)" = "function" ]; then
	complete -F _known_hosts sshx
fi

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
