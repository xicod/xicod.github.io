#!/bin/bash

function setParam {
	sed -i "s/[\s#]*\<$1\>\s*\(yes\|no\)/$1 $2/" /etc/ssh/sshd_config
}

setParam PasswordAuthentication no

# this is deprecated in favor of KbdInteractiveAuthentication
setParam ChallengeResponseAuthentication no

setParam KbdInteractiveAuthentication no

setParam UsePAM yes

