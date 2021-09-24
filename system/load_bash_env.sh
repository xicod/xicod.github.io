#!/bin/bash

dt_repo_dl_prefix="https://raw.githubusercontent.com/xicod/xicod.github.io/gitconfig/system/dotfiles"

function createTempFileFromUrl {
	local t=$(mktemp --tmpdir bash.tmp.XXXXXXXXXX) \
		&& tmp_files+=($t) \
		&& curl -sSf "$1" >$t
}

# check if already exists, then don't everride with empty
if [ -z ${tmp_files+x} ]; then
	tmp_files=()
fi

function trap_tempConfFilesDelete {
	for f in "${tmp_files[@]}"; do
		command rm $f
	done
}
trap "trap_tempConfFilesDelete" EXIT

: \
&& source <(curl -sSf ${dt_repo_dl_prefix}/dt-env-common.sh) \
&& createTempFileFromUrl ${dt_repo_dl_prefix}/vimrc \
&& export VIMINIT="source ${tmp_files[-1]}" \
&& createTempFileFromUrl ${dt_repo_dl_prefix}/tigrc \
&& export TIGRC_USER=${tmp_files[-1]} \
&& createTempFileFromUrl ${dt_repo_dl_prefix}/gitconfig \
&& export GIT_CONFIG_SYSTEM=${tmp_files[-1]} \
&& export GIT_CONFIG_GLOBAL= \
&& createTempFileFromUrl ${dt_repo_dl_prefix}/gitignore_global \
&& __dt_set_git_env_conf core.excludesfile ${tmp_files[-1]}


