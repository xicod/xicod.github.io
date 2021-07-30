#!/bin/bash

function setParam {
	sed -i "s/[\s#]*\<$1\>\s*\(yes\|no\)/$1 $2/" /etc/ssh/sshd_config
}

setParam PasswordAuthentication no
setParam ChallengeResponseAuthentication no
setParam UsePAM no

