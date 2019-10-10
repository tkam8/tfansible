if [ "$UID" = 0 ]; then
	PS1="[\u@/home/tfansible] [\w] # "
else
	PS1="[\u@/home/tfansible] [\w] $ "
fi