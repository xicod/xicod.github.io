
if [ "$EUID" = "0" ] || [ "$USER" = "root" ] ; then
	export PATH="${PATH}:__PARENT_GIT_REPO__/scripts/root/bin"
fi

export PATH="${PATH}:~/bin:__TOOLS_DIR__"

# cron sometimes sets HOME=/
export HOME=$(getent passwd $(whoami) | cut -d':' -f6)
