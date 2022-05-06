#! /usr/bin/bash


filename="/etc/tacheron/tacherontab"
path="/etc/tacheron"
op=0

if [ ! -d "$path" ];then
	mkdir "$path"
fi


user=`whoami`

while [ $# -gt 0 ];do
	if [ $1 = "-l" ];then
		op=0
	elif [ $1 = "-r" ];then
		op=1
	elif [ $1 = "-e" ];then
		op=2
	elif [ $1 = "-u" ];then
		shift
		user=$1
	else
		echo "tacherontab [-u user] {-l | -r | -e}"
		exit
	fi
	shift
done


if [ $op -eq 0 ];then
	cat "${filename}${user}"
elif [ $op -eq 1 ];then
	rm "${filename}${user}"
else
	vi "${filename}${user}"
fi
