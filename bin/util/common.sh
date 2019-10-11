print() {
	echo "-----> $*"
}

indent() {
	c='s/^/       /'
	case $(uname) in
	Darwin) sed -l "$c";;
	*)      sed -u "$c";;
	esac
}

get_os() {
	uname | tr '[:upper:]' '[:lower:]'
}

get_cpu() {
	if [[ "$(uname -p)" = "i686" ]]; then
	echo "x86"
	else
	echo "x64"
	fi
}

get_platform() {
	os=$(get_os)
	cpu=$(get_cpu)
	echo "$os-$cpu"
}

get_linux_platform_version() {
	if [ -e /etc/os-release ]; then
	    . /etc/os-release
	    echo ${VERSION_ID//[a-z]/}
	    return 0
	fi

	print "Linux specific platform version could not be detected: UName = $uname"
	return 1
}

error() {
	local c="2,999 s/^/ !     /"
	# send all of our output to stderr
	exec 1>&2

	echo -e "\033[1;31m" # bold; red
	echo -n " !     ERROR: "
	# this will be fed from stdin
	case $(uname) in
		Darwin) sed -l "$c";; # mac/bsd sed: -l buffers on line boundaries
		*)      sed -u "$c";; # unix/gnu sed: -u unbuffered (arbitrary) chunks of data
	esac
	echo -e "\033[0m" # reset style
	exit 1
}

export_env_dir() {
	local env_dir=$1
	if [ -d "$env_dir" ]; then
		local whitelist_regex=${2:-''}
		local blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH|LANG|BUILD_DIR)$'}
		# shellcheck disable=SC2164
		pushd "$env_dir" >/dev/null
		for e in *; do
			[ -e "$e" ] || continue
			echo "$e" | grep -E "$whitelist_regex" | grep -qvE "$blacklist_regex" &&
			export "$e=$(cat "$e")"
			:
		done
		# shellcheck disable=SC2164
		popd >/dev/null
	fi
}

get_project_file() {
	local projectfile=$(x=$(dirname $(find $1 -maxdepth 1 -type f | head -1)); while [[ "$x" =~ $1 ]] ; do find "$x" -maxdepth 1 -name *.csproj; x=`dirname "$x"`; done)
	echo $projectfile
}

get_project_name() {
	local project_name=""
	local project_file="$(get_project_file $1)"
	if [[ $project_file ]]; then
		project_name=$(basename ${project_file%.*})
	fi
	echo $project_name
}

get_framework_version() {
	local target_framework=$(grep -oPm1 "(?<=<TargetFramework>)[^<]+" $1/*.csproj)
	if [[ $target_framework =~ ";" ]]; then
	 	echo $(cut -d ';' -f 1 <<< $target_framework)
	else
		echo ${target_framework//[a-z]/}
	fi
}

get_runtime_framework_version() {
	local runtime_framework_version=$(grep -oPm1 "(?<=<RuntimeFrameworkVersion>)[^<]+" $1/*.csproj)
	if [[ ${#runtime_framework_version} -eq 0 ]]; then
		echo "Latest"
	else
		echo "${runtime_framework_version//[a-z]/}"
	fi
}

get_netcore_version() {
	local netcoreversion="2.2.401" # set dotnet default version
	if [ $1 == "netcoreapp2.1" ]; then
		netcoreversion="2.1.403"
	elif [ $1 == "netcoreapp2.2" ]; then
		netcoreversion="2.2.402"
	elif [ $1 == "netcoreapp3.0" ]; then
		netcoreversion="3.0.100"
	fi
	echo $netcoreversion
}

decimal_compare() {
   awk -v n1="$1" -v n2="$2" 'BEGIN {printf "%s " "$3" " %s\n", n1, n2}'
}
