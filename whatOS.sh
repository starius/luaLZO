# /bin/sh


UNAME=`uname 2> dummy.tmp || echo "false"`
RM="rm"

case $UNAME in
	false)
		os="__NoUname__"
		;;
	Darwin)
		if test "`uname -p`" = "powerpc"
		then
			os="OSX"
		else
			os="UNIX"
		fi
		;;
	Linux | linux | linux-gnu)
		os="LINUX"
		;;
	win32 | migw32 | mingw | cygwin)
		os="WIN32"
		RM="del"
		;;
	*)
		os="UNIX"
		;;
esac

if test "$os" = "__NoUname__"
then
	# ??
	os="UNIX"
fi

$RM dummy.tmp
echo $os

