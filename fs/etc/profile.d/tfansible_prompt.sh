if [ "$UID" = 0 ]; then
	PS1="[\u@tfansible] [\w] # "
else
	PS1="[\u@tfansible] [\w] $ "
fi