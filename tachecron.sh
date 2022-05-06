#! /usr/bin/bash

logpath="/var/log/tacheron"
tablepath="/etc/tacheron/tacherontab"

#allow/deny
allowpath="/etc/tacheron.allow"
denypath="/etc/tacheron.deny"
whitelist=""
blacklist=""
whitelist_mode=0
blacklist_mode=0

#temp data
L=0
I=0
F=""

#current time
S=0
M=0
H=0
D=0
m=0
W=0


verify_user()
{
	if [ $1 = "root" ];then
		return 0
	fi
	
	if [ $whitelist_mode -eq 1 ];then
		if [ $1 = "root" ];then
			return 0
		fi
		for u in $whitelist
		{
			if [ $u = $1 ];then
				return 0
			fi
		}
		return 1
	elif [ $blacklist_mode -eq 1 ];then
		for u in $blacklist
		{
			if [ $u = $1 ];then
				return 1
			fi
		}
		return 0
	else
		return 1
	fi
}


get_digit()
{
	if [ "$1" = "0" ];then
		return 0
	elif [ "$1" = "1" ];then
		return 1
	elif [ "$1" = "2" ];then
		return 2
	elif [ "$1" = "3" ];then
		return 3
	elif [ "$1" = "4" ];then
		return 4
	elif [ "$1" = "5" ];then
		return 5
	elif [ "$1" = "6" ];then
		return 6
	elif [ "$1" = "7" ];then
		return 7
	elif [ "$1" = "8" ];then
		return 8
	elif [ "$1" = "9" ];then
		return 9
	fi
	
	return 100
}


input_num()
{
	num=0
	flags=0
	
	while [ $I -lt $L ];do
		get_digit "${F:$I:1}"
		nn=$?
		
		if [ $nn -gt 9 ];then
			break
		fi
		flags=1
		
		
		let num=num*10+nn
		let I=I+1
	done
	
	if [ $flags -eq 1 ];then
		return $num
	fi
	return 100
}


can_run3()
{
	x=0
	y=0
	
	if [ ! "${F:$I:1}" = "*" ];then
		input_num
		n=$?
		if [ $n -eq 100 ];then
			return 1
		fi
		x=$n
		y=$n
		
		if [ "${F:$I:1}" = "-" ];then
			let I=I+1
			input_num
			n=$?
			if [ $n -eq 100 ];then
				return 1
			fi
			y=$n
		fi
	else
		x=$2
		y=$3
		let I=I+1		
	fi
	
	if [ $1 -gt $y ];then
		return 1
	fi
	
	if [ $1 -lt $x ];then
		return 1
	fi
	
	
	while [ $I -lt $L ];do
		if [ "${F:$I:1}" = "," ];then
			break
		elif [ "${F:$I:1}" = "~" ];then
			let I=I+1
			input_num
			n=$?
			if [ $n -eq 100 ];then
				return 1
			fi
			if [ $n -eq $1 ];then
				return 1
			fi
		elif [ "${F:$I:1}" = "/" ];then
			let I=I+1
			input_num
			n=$?
			if [ $n -eq 100 ];then
				return 1
			fi
			if [ $n -eq 0 ];then
				return 1
			fi
			
			r=$(( $1 % $n ))
			if [ ! $r -eq 0 ];then
				return 1
			fi
		else
			let I=I+1
		fi
	done
}


can_run2()
{
	F="$1"
	L=${#F}
	I=0
	
	while [ $I -lt $L ];do
		can_run3 $2 $3 $4
		if [ $? -eq 0 ];then
			return 0
		fi
		let I=I+1
	done
	
	return 1
}


runcmd()
{
	echo "$1"
	ret=`$1`
	
	echo "`date` running cmd '$1'" >> $logpath
	echo "$ret" >> $logpath
}


can_run()
{
	let r=S%15
	if [ ! $r -eq 0 ];then
		return
	fi
	let r=S/15
	
	can_run2 "$6" $W 0 6
	if [ ! $? -eq 0 ];then
		return
	fi	
	can_run2 "$5" $m 1 12
	if [ ! $? -eq 0 ];then
		return
	fi	
	can_run2 "$4" $D 1 31
	if [ ! $? -eq 0 ];then
		return
	fi	
	can_run2 "$3" $H 0 23
	if [ ! $? -eq 0 ];then
		return
	fi	
	can_run2 "$2" $M 0 59
	if [ ! $? -eq 0 ];then
		return
	fi	
	can_run2 "$1" $r 0 3
	if [ ! $? -eq 0 ];then
		return
	fi
	
	runcmd "$7"
}


if [ -e $allowpath ];then
	whitelist=`cat $allowpath`
	if [ ! $? -eq 0 ];then
		whitelist=""
	else
		whitelist_mode=1
	fi
fi

if [ -e $denypath ];then
	blacklist=`cat $denypath`
	if [ ! $? -eq 0 ];then
		blacklist=""
	else
		blacklist_mode=1
	fi
fi

while [ true ];do
	S=`date +%-S`
	M=`date +%-M`
	H=`date +%-H`
	D=`date +%-d`
	m=`date +%-m`
	W=`date +%-w`
	
	for table in `ls ${tablepath}*`
	{
		username=${table:${#tablepath}}
		verify_user $username
		if [ $? -eq 0 ];then
			cat $table | while read a b c x y z cmd;do can_run "$a" "$b" "$c" "$x" "$y" "$z" "$cmd" ;done
		fi
	}

	sleep 1
done




















