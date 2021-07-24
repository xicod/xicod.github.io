GLOBAL_BIN_DEST_DIR=/tools
BASH_ENV_DEST := $(shell bash -c '[ -d /etc/bash/bashrc.d ] && echo "/etc/bash/bashrc.d" || echo /etc/profile.d')

all:
	@echo "Copying tools"
	mkdir -p $(GLOBAL_BIN_DEST_DIR)
	cp -a tools/* $(GLOBAL_BIN_DEST_DIR)/
	@echo "-------------------------------------------"
	@echo "Setting vimrc"
	cp -a ./dotfiles/vimrc /etc/vim/vimrc.local
	@echo "-------------------------------------------"
	@echo "Setting tigrc"
	bash -c "echo -e 'source /etc/tigrc\nsource /etc/tigrc-dt' > /etc/tigrc-custom"
	cp -a ./dotfiles/tigrc /etc/tigrc-dt
	@echo "-------------------------------------------"
	@echo "Setting dt-env-common.sh"
	cp -a ./dotfiles/dt-env-common.sh $(BASH_ENV_DEST)/
	@echo "-------------------------------------------"
	@echo "Setting gitconfig"
	cp -a ./dotfiles/gitconfig /etc/
	cp -a ./dotfiles/gitignore_global /etc/
ifeq ($(shell cat /root/main_host 2>/dev/null), 1)
	@echo "-------------------------------------------"
	@echo "Setting system tmux.conf"
	cp -a ./dotfiles/tmux.conf /etc/
endif
