BASH_ENV_DEST := $(shell bash -c '[ -d /etc/bash/bashrc.d ] && echo "/etc/bash/bashrc.d" || echo /etc/profile.d')

all:
	@echo "Setting profile"
	./place_profile.sh
	@echo "-------------------------------------------"
	@echo "Copying tools"
	./place_tools.sh
	@echo "-------------------------------------------"
	@echo "Setting vimrc"
	cp -a ./dotfiles/vimrc /etc/vim/vimrc.local
	@echo "-------------------------------------------"
	@echo "Setting tigrc"
	bash -c "echo -e 'source /etc/tigrc\nsource /etc/tigrc-dt' > /etc/tigrc-custom"
	cp -a ./dotfiles/tigrc /etc/tigrc-dt
	@echo "-------------------------------------------"
	@echo "Setting htoprc"
	cp -a ./dotfiles/htoprc /etc/htoprc
	@echo "-------------------------------------------"
	@echo "Setting dt-env-common.sh"
	cp -a ./dotfiles/dt-env-common.sh $(BASH_ENV_DEST)/
	@echo "-------------------------------------------"
	@echo "Setting gitconfig"
	cp -a ./dotfiles/gitconfig /etc/
	cp -a ./dotfiles/gitignore_global /etc/
ifeq ($(shell test -d /etc/ssh/sshd_config.d && echo 1 || echo 0), 1)
	@echo "-------------------------------------------"
	@echo "Setting sshd_config"
	cp -a ./dotfiles/sshd_config_99dt.conf /etc/ssh/sshd_config.d/99dt.conf
endif
ifeq ($(shell cat /root/main_host 2>/dev/null), 1)
	@echo "-------------------------------------------"
	@echo "Setting system tmux.conf"
	cp -a ./dotfiles/tmux.conf /etc/
endif
	@echo "-------------------------------------------"
	./place_default_dt_config.sh
	@echo "-------------------------------------------"
	@echo "Setting cronfile"
	./place_cronjobs.sh
