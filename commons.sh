function errExit() {
	echo $1
	exit 1
}

function exitIfFail() {
	[ $? -ne 0 ] && errExit "$@"
}

BeginErrCheck='set -e'
EndErrCheck='set +e'

function writeScript() {
    filename="$1"
    shift
    echo "$@" >> "$filename" 
}

set -x
set -e