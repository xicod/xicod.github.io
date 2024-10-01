#!/bin/bash

sed \
	-e 's|^\(+\s*/.*\)$|<span style="color: green;">\1</span>|' \
	-e 's|^\(-\s*/.*\)$|<span style="color: red;">\1</span>|' \
	-e 's|^\(M\s*/.*\)$|<span style="color: blue;">\1</span>|' \
	-e 's|$|<br>|'
