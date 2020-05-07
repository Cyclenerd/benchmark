#!/bin/bash

# benchmark.sh
# Author: Nils Knieling - https://github.com/Cyclenerd/benchmark

#
# Bash Script which runs several Linux benchmarks (Sysbench, UnixBench and Geekbench)
#
# Currently only tested with Ubuntu. Should also work with every other Linux distribution.
# Please note the requirements. More information can be found in the README.md
#

cat << EOF

 _                     _                          _          _     
| |                   | |                        | |        | |    
| |__   ___ _ __   ___| |__  _ __ ___   __ _ _ __| | __  ___| |__  
| '_ \ / _ \  _ \ / __|  _ \|  _  _ \ /  _  |  __| |/ / / __|  _ \ 
| |_) |  __/ | | | (__| | | | | | | | | (_| | |  |   < _\__ \ | | |
|_.__/ \___|_| |_|\___|_| |_|_| |_| |_|\__,_|_|  |_|\_(_)___/_| |_|

EOF

#####################################################################
#### Configuration Section
#####################################################################

# Storage for downloaded files and IO / tests
# Typically $HOME (/root/benchmark) is a good place.
# You need approximately 10 GB of free space.
MY_DIR="$HOME/benchmark"

# Location for the HTML benchmark results
# This can also be $MY_DIR (/root/benchmark/output.html)
MY_OUTPUT="$MY_DIR/output.html"

# Benchmarks without package for Linux distribution
# These benchmark programs are loaded:
MY_UNIXBENCH_DOWNLOAD_URL="https://www.nkn-it.de/backup/byte-unixbench-5.1.3.tar.gz"
#MY_UNIXBENCH_DOWNLOAD_URL="https://github.com/kdlucas/byte-unixbench/archive/v5.1.3.tar.gz"
MY_GEEKBENCH_DOWNLOAD_URL="http://cdn.geekbench.com/Geekbench-5.1.1-Linux.tar.gz"

# Unlock Geekbench using EMAIL and KEY
# If you purchased Geekbench, enter your email address and license
# key from your email receipt with the following command line:
#    benchmark.sh -e <EMAIL> -k <KEY>
# As an alternative you can also save your data as follows:
MY_GEEKBENCH_EMAIL=""
MY_GEEKBENCH_KEY=""

# GitHub API personal access token with scope `gist` (Create gists)
#    benchmark.sh -g <TOKEN>
MY_GITHUB_API_TOKEN=""
MY_GITHUB_API_JSON="$MY_DIR/github-gist.json"
MY_GITHUB_API_LOG="$MY_DIR/github-gist.log"

# Set maximal traceroute hop count
MY_TRACEROUTE_MAX_HOP="15"

#####################################################################
#### END Configuration Section
#####################################################################


ME=$(basename "$0")
MY_DATE_TIME=$(date -u "+%Y-%m-%d %H:%M:%S")
MY_DATE_TIME+=" UTC"
MY_TIMESTAMP_START=$(date "+%s")
MY_GEEKBENCH_NO_UPLOAD=""

#####################################################################
# Terminal output helpers
#####################################################################

function usage {
	returnCode="$1"
	echo
	echo -e "Usage: 
	$ME [-e <EMAIL>] [-k <KEY>] [-n] [-h]"
	echo -e "Options:
	[-e <EMAIL>]\\t unlock Geekbench using EMAIL and KEY (default: $MY_GEEKBENCH_EMAIL)
	[-k <KEY>]\\t unlock Geekbench using EMAIL and KEY (default: $MY_GEEKBENCH_KEY)
	[-n]\\t\\t do not upload results to the Geekbench Browser (only if unlocked)
	[-g <TOKEN>]\\t GitHub API personal access token, create new gist with results (default: $MY_GEEKBENCH_KEY)
	[-h]\\t\\t displays help (this message)"
	echo
	exit "$returnCode"
}

# echo_title() outputs a title to stdout and MY_OUTPUT
function echo_title() {
	echo "> $1"
	echo "<h1>$1</h1>" >> "$MY_OUTPUT"
}

# echo_step() outputs a step to stdout and MY_OUTPUT
function echo_step() {
	echo "    > $1"
	echo "<h2>$1</h2>" >> "$MY_OUTPUT"
}

# echo_sub_step() outputs a step to stdout and MY_OUTPUT
function echo_sub_step() {
	echo "      > $1"
	echo "<h3>$1</h3>" >> "$MY_OUTPUT"
}

# echo_code() outputs <pre> or </pre> to MY_OUTPUT
function echo_code() {
	case "$1" in
		start)
			echo "<pre>" >> "$MY_OUTPUT"
			;;
		end)
			echo "</pre>" >> "$MY_OUTPUT"
			;;
	esac
}

# echo_equals() outputs a line with =
function echo_equals() {
	COUNTER=0
	while [  $COUNTER -lt "$1" ]; do
		printf '='
		((COUNTER=COUNTER+1)) 
	done
}

# echo_line() outputs a line with 70 =
function echo_line() {
	echo_equals "90"
	echo
}

# exit_with_failure() outputs a message before exiting the script.
function exit_with_failure() {
	echo
	echo "FAILURE: $1"
	echo
	exit 9
}

#####################################################################
# Other helpers
#####################################################################

# command_exists() tells if a given command exists.
function command_exists() {
	command -v "$1" >/dev/null 2>&1
}

# perl_module_exists() tells if a given perl module exists.
function perl_module_exists() {
	perl -M"$1" -e 1 >/dev/null 2>&1
}

# check_if_root_or_die() verifies if the script is being run as root and exits
# otherwise (i.e. die).
function check_if_root_or_die() {
	SCRIPT_UID=$(id -u)
	if [ "$SCRIPT_UID" != 0 ]; then
		exit_with_failure "$ME should be run as root"
	fi
}

# check_operating_system() obtains the operating system and exits if it's not testet
function check_operating_system() {
	MY_UNAME_S="$(uname -s 2>/dev/null)"
	if [ "$MY_UNAME_S" = "Linux" ]; then
		echo "    > Operating System: Linux"
	else
		exit_with_failure "Unsupported operating system 'MY_UNAME_S'. Please use 'Linux' or edit this script :-)"
	fi
}

# hostname_fqdn() get full (FQDN) hostname
function hostname_fqdn() {
	echo_step "Hostname (FQDN)"
	if hostname -f &>/dev/null; then
		hostname -f >> "$MY_OUTPUT"
	elif hostname &>/dev/null; then
		hostname >> "$MY_OUTPUT"
	else
		echo "Hostname could not be determined"
	fi
}

# cpu_info() cat /proc/cpuinfo to MY_OUTPUT
function cpu_info() {
	echo_step "CPU Info"
	if [[ -f "/proc/cpuinfo" ]]; then
		MY_CPU_COUNT=$(grep -c processor /proc/cpuinfo)
		echo_code start
		cat "/proc/cpuinfo" >> "$MY_OUTPUT"
		echo_code end
	else
		exit_with_failure "'/proc/cpuinfo' does not exist"
	fi
}

# mem_info() cat /proc/meminfo to MY_OUTPUT
function mem_info() {
	echo_step "RAM Info"
	if [[ -f "/proc/meminfo" ]]; then
		echo_code start
		cat "/proc/meminfo" >> "$MY_OUTPUT"
		echo_code end
	else
		exit_with_failure "'/proc/meminfo' does not exist"
	fi
	
	echo_step "Free"
	echo_code start
	free -m >> "$MY_OUTPUT"
	echo_code end
}

# network_info() cat /etc/resolv.conf to MY_OUTPUT
function network_info() {
	echo_step "Network Card"
	echo_code start
	lspci -nnk | grep -i net -A2 >> "$MY_OUTPUT"
	echo_code end
	
	echo_step "Ifconfig"
	echo_code start
	ifconfig >> "$MY_OUTPUT"
	echo_code end
	
	echo_step "Nameserver"
	if [[ -f "/etc/resolv.conf" ]]; then
		echo_code start
		cat "/etc/resolv.conf" >> "$MY_OUTPUT"
		echo_code end
	else
		exit_with_failure "'/etc/resolv.conf' does not exist"
	fi
}

# disk_info() df -h to MY_OUTPUT
function disk_info() {
	echo_step "Disk Info"
	echo_code start
	df -h >> "$MY_OUTPUT"
	echo_code end
}

# traceroute_benchmark() traceroute to MY_OUTPUT
function traceroute_benchmark() {
	echo_step "Traceroute ($1)"
	echo_code start
	traceroute -m "$MY_TRACEROUTE_MAX_HOP" "$1" >> "$MY_OUTPUT" 2>&1
	echo_code end
}

# ping_benchmark() ping to MY_OUTPUT
function ping_benchmark() {
	echo_step "Ping ($1)"
	echo_code start
	ping -c 10 "$1" >> "$MY_OUTPUT" 2>&1
	echo_code end
}

# download_benchmark() curl speed to MY_OUTPUT
function download_benchmark() {
	echo_step "Download from $1 ($2)"
	
	if MY_CURL_STATS=$(curl -f -w '%{speed_download}\t%{time_namelookup}\t%{time_total}\n' -o /dev/null -s "$2"); then
		MY_CURL_SPEED=$(echo "$MY_CURL_STATS" | awk '{print $1}')
		MY_CURL_DNSTIME=$(echo "$MY_CURL_STATS" | awk '{print $2}')
		MY_CURL_TOTALTIME=$(echo "$MY_CURL_STATS" | awk '{print $3}')
		echo_code start
		{
			echo "Speed: $MY_CURL_SPEED"
			echo "DNS: $MY_CURL_DNSTIME sec"
			echo "Total Time: $MY_CURL_TOTALTIME sec"
		} >> "$MY_OUTPUT"
		echo_code end
		
	else
		echo "Error"
	fi
}


#####################################################################
# MAIN
#####################################################################

echo_line

while getopts "ne:k:g:h" opt; do
	case $opt in
	n)
		MY_GEEKBENCH_NO_UPLOAD="1"
		;;
	e)
		MY_GEEKBENCH_EMAIL="$OPTARG"
		;;
	k)
		MY_GEEKBENCH_KEY="$OPTARG"
		;;
	g)
		MY_GITHUB_API_TOKEN="$OPTARG"
		;;
	h)
		usage 0
		;;
	*)
		usage 1
		;;
	esac
done

#####################################################################
# Check the requirements
#
# These Ubuntu packages should be installed:
#  curl 
#  make
#  gcc
#  build-essential
#  net-tools
#  traceroute
#  perl
#  lshw 
#  ioping
#  fio
#  sysbench
#####################################################################

echo "> Check the Requirements"

check_if_root_or_die
check_operating_system
if [[ ! -d "$MY_DIR" ]]; then
	mkdir "$MY_DIR" || exit_with_failure "Could not create folder '$MY_DIR'"
fi
echo "<html>" > "$MY_OUTPUT" || exit_with_failure "Could not write to output file '$MY_OUTPUT'"
if ! command_exists curl; then
	exit_with_failure "'curl' is needed. Please install 'curl'. More details can be found at https://curl.haxx.se/"
fi
if ! command_exists make; then
	exit_with_failure "'make' is needed. Please install development tools (Ubuntu package 'build-essential') for your operating system."
fi
if ! command_exists gcc; then
	exit_with_failure "'gcc' is needed. Please install development tools (Ubuntu package 'build-essential') for your operating system."
fi
if ! command_exists perl; then
	exit_with_failure "'perl' is needed. Please install 'perl'. More details can be found at https://www.perl.org/get.html"
fi
if ! command_exists ifconfig; then
	exit_with_failure "'ifconfig' is needed. Please install network tools (Ubuntu package 'net-tools') for your operating system."
fi
if ! command_exists ping; then
	exit_with_failure "'ping' is needed. Please install network tools (Ubuntu package 'net-tools') for your operating system."
fi
if ! command_exists traceroute; then
	exit_with_failure "'traceroute' is needed. Please install 'traceroute'."
fi
if ! command_exists dd; then
	exit_with_failure "'dd' is needed. Please install 'dd'. More details can be found at https://www.gnu.org/software/coreutils/manual/"
fi
if ! command_exists lshw; then
	exit_with_failure "'lshw' is needed. Please install 'lshw'. More details can be found at http://www.ezix.org/project/wiki/HardwareLiSter"
fi
if ! command_exists ioping; then
	exit_with_failure "'ioping' is needed. Please install 'ioping'. More details can be found at https://github.com/koct9i/ioping"
fi
if ! command_exists fio; then
	exit_with_failure "'fio' is needed. Please install 'fio'. More details can be found at https://wiki.mikejung.biz/Benchmarking#Fio_Installation"
fi
if ! command_exists sysbench; then
	exit_with_failure "'sysbench' is needed. Please install 'sysbench'. More details can be found at https://github.com/akopytov/sysbench"
fi
if ! perl_module_exists "Time::HiRes"; then
	exit_with_failure "Perl module 'Time::HiRes' is needed. Please install 'Time::HiRes'. More details can be found at http://www.cpan.org/modules/INSTALL.html"
fi
if ! perl_module_exists "IO::Handle"; then
	exit_with_failure "Perl module 'IO::Handle' is needed. Please install 'IO::Handle'. More details can be found at http://www.cpan.org/modules/INSTALL.html"
fi

# Download and build UnixBench
echo "    > Download UnixBench"
if curl -fsL "$MY_UNIXBENCH_DOWNLOAD_URL" -o "$MY_DIR/unixbench.tar.gz"; then
	if tar xvfz "$MY_DIR/unixbench.tar.gz" -C "$MY_DIR" --strip-components=1 > /dev/null 2>&1; then
		cd "$MY_DIR/UnixBench" || exit_with_failure "Could not find folder '$MY_DIR/UnixBench'"
		if make > /dev/null 2>&1; then
			echo "        > UnixBench successfully downloaded and compiled"
		else
			exit_with_failure "Could not build (make) UnixBench"
		fi
	else
		exit_with_failure "Could not unpack '$MY_DIR/unixbench.tar.gz'"
	fi
else
	exit_with_failure "Could not download UnixBench '$MY_UNIXBENCH_DOWNLOAD_URL'"
fi

# Download Geekbench 5
echo "    > Download Geekbench 5"
if curl -fsL "$MY_GEEKBENCH_DOWNLOAD_URL" -o "$MY_DIR/geekbench.tar.gz"; then
	if tar xvfz "$MY_DIR/geekbench.tar.gz" -C "$MY_DIR" --strip-components=1 > /dev/null 2>&1; then
		if [[ -x "$MY_DIR/geekbench5" ]]; then
			echo "        > Geekbench successfully downloaded"
		else
			exit_with_failure "Could not find '$MY_DIR/geekbench5'"
		fi
	else
		exit_with_failure "Could not unpack '$MY_DIR/geekbench.tar.gz'"
	fi
else
	exit_with_failure "Could not download Geekbench '$MY_GEEKBENCH_DOWNLOAD_URL'"
fi

# Unlock Geekbench 5
if [[ $MY_GEEKBENCH_EMAIL && $MY_GEEKBENCH_KEY ]]; then
	if "$MY_DIR/geekbench5" --unlock "$MY_GEEKBENCH_EMAIL" "$MY_GEEKBENCH_KEY" > /dev/null 2>&1; then
		echo "        > Geekbench successfully unlocked"
	else
		exit_with_failure "Could not unlock Geekbench"
	fi
else
	echo "        > Geekbench is in tryout mode"
fi

#####################################################################
# Let's start
#####################################################################

echo_line
echo
echo " Depending on the hardware, the runtime is slightly longer."
echo
echo "      Please be patient..!"
echo
echo_line


#####################################################################
# Get System info and versions
#####################################################################

echo_title "System Info"

hostname_fqdn

echo_step "Kernel"; uname -a >> "$MY_OUTPUT"

echo_step "Date and Time"; echo "$MY_DATE_TIME" >> "$MY_OUTPUT"

echo_step "Hardware Lister (lshw)"
echo_code start
lshw >> "$MY_OUTPUT"
echo_code end

cpu_info

mem_info

network_info


#####################################################################
# Versions
#####################################################################

echo_step "Versions"

echo_sub_step "Bash"
echo "$BASH_VERSION" >> "$MY_OUTPUT"
	
echo_sub_step "gcc"
echo_code start 
gcc -v >> "$MY_OUTPUT" 2>&1
echo_code end
	
echo_sub_step "make"
echo_code start
make -v >> "$MY_OUTPUT" 2>&1
echo_code end
	
echo_sub_step "Perl"
echo_code start
perl -v >> "$MY_OUTPUT" 2>&1
echo_code end


#####################################################################
# Run bandwidth benchmarks
#####################################################################

echo_title "Bandwidth Benchmark"

# Cachefly
ping_benchmark "cachefly.cachefly.net"
# Hetzner, Nuernberg, Germany
ping_benchmark "hetzner.de"
# Germany (Frankfurt)
ping_benchmark "ftp.hostserver.de"
# IPv6
ping_benchmark "ipv6.test-ipv6.com"

traceroute_benchmark "cachefly.cachefly.net"
traceroute_benchmark "hetzner.de"
traceroute_benchmark "ftp.hostserver.de"

download_benchmark 'Cachefly' 'http://cachefly.cachefly.net/100mb.test'
#download_benchmark 'Linode, Atlanta, GA, USA' 'http://speedtest.atlanta.linode.com/100MB-atlanta.bin'
#download_benchmark 'Linode, Dallas, TX, USA' 'http://speedtest.dallas.linode.com/100MB-dallas.bin'
#download_benchmark 'Linode, Tokyo, JP' 'http://speedtest.tokyo.linode.com/100MB-tokyo.bin'
#download_benchmark 'Linode, London, UK' 'http://speedtest.london.linode.com/100MB-london.bin'
#download_benchmark 'OVH, Paris, France' 'http://proof.ovh.net/files/100Mio.dat'
#download_benchmark 'SmartDC, Rotterdam, Netherlands' 'http://mirror.i3d.net/100mb.bin'
download_benchmark 'Hetzner, Nuernberg, Germany' 'http://speed.hetzner.de/100MB.iso'
#download_benchmark 'iiNet, Perth, WA, Australia' 'http://ftp.iinet.net.au/test100MB.dat'
#download_benchmark 'Leaseweb, Haarlem, NL' 'http://mirror.nl.leaseweb.net/speedtest/100mb.bin'
#download_benchmark 'Leaseweb, Manassas, VA, USA' 'http://mirror.us.leaseweb.net/speedtest/100mb.bin'
#download_benchmark 'Softlayer, Singapore' 'http://speedtest.sng01.softlayer.com/downloads/test100.zip'
#download_benchmark 'Softlayer, Seattle, WA, USA' 'http://speedtest.sea01.softlayer.com/downloads/test100.zip'
#download_benchmark 'Softlayer, San Jose, CA, USA' 'http://speedtest.sjc01.softlayer.com/downloads/test100.zip'
#download_benchmark 'Softlayer, Washington, DC, USA' 'http://speedtest.wdc01.softlayer.com/downloads/test100.zip'


#####################################################################
# Run I/O benchmarks
#####################################################################

echo_title "I/O Benchmark"

# DD
echo_step "dd 1Mx1k fdatasync"
echo_code start
MY_DD=$(dd if="/dev/zero" of="$MY_DIR/io-test" bs=1M count=1k conv=fdatasync 2>&1)
echo "$MY_DD" >> "$MY_OUTPUT"
echo_code end

echo_step "dd 64kx16k fdatasync"
echo_code start
MY_DD=$(dd if="/dev/zero" of="$MY_DIR/io-test" bs=64k count=16k conv=fdatasync 2>&1)
echo "$MY_DD" >> "$MY_OUTPUT"
echo_code end

echo_step "dd 1Mx1k dsync"
echo_code start
MY_DD=$(dd if="/dev/zero" of="$MY_DIR/io-test" bs=1M count=1k oflag=dsync 2>&1)
echo "$MY_DD" >> "$MY_OUTPUT"
echo_code end

echo_step "dd 64kx16k dsync"
echo_code start
MY_DD=$(dd if="/dev/zero" of="$MY_DIR/io-test" bs=64k count=16k oflag=dsync 2>&1)
echo "$MY_DD" >> "$MY_OUTPUT"
echo_code end

# IOPing
echo_step "IOPing"
echo_code start
ioping -c 10 "$MY_DIR/" >> "$MY_OUTPUT"
echo_code end

echo_step "IOPing seek rate"
echo_code start
ioping -RD "$MY_DIR/" >> "$MY_OUTPUT"
echo_code end

echo_step "IOPing sequential"
echo_code start
ioping -RL "$MY_DIR/" >> "$MY_OUTPUT"
echo_code end

echo_step "IOPing cached"
echo_code start
ioping -RC "$MY_DIR/" >> "$MY_OUTPUT"
echo_code end

# FIO
echo_step "FIO full write pass"
echo_code start
fio --name=writefile --size=10G --filesize=10G \
	--filename="$MY_DIR/io-test" \
	--bs=1M --nrfiles=1 \
	--direct=1 --sync=0 --randrepeat=0 --rw=write --refill_buffers --end_fsync=1 \
	--iodepth=200 --ioengine=libaio >> "$MY_OUTPUT"
echo_code end

echo_step "FIO rand read"
echo_code start
fio --time_based --name=benchmark --size=10G --runtime=30 \
	--filename="$MY_DIR/io-test" \
	--ioengine=libaio --randrepeat=0 \
	--iodepth=128 --direct=1 --invalidate=1 --verify=0 --verify_fatal=0 \
	--numjobs=4 --rw=randread --blocksize=4k --group_reporting >> "$MY_OUTPUT"
echo_code end

echo_step "FIO rand write"
echo_code start
fio --time_based --name=benchmark --size=10G --runtime=30 \
	--filename="$MY_DIR/io-test" \
	--ioengine=libaio --randrepeat=0 \
	--iodepth=128 --direct=1 --invalidate=1 --verify=0 --verify_fatal=0 \
	--numjobs=4 --rw=randwrite --blocksize=4k --group_reporting >> "$MY_OUTPUT"
echo_code end


#####################################################################
# Run SysBench
#####################################################################

echo_title "SysBench"

echo_step "SysBench Single-Core CPU performance test (1 thread)"
echo_code start
sysbench cpu --cpu-max-prime=20000 --threads=1 run >> "$MY_OUTPUT"
echo_code end

if [[ $MY_CPU_COUNT -gt "0" ]]; then
	echo_step "SysBench Multi-Core CPU performance test ($MY_CPU_COUNT threads)"
	echo_code start
	sysbench cpu --cpu-max-prime=20000 --threads="$MY_CPU_COUNT" run >> "$MY_OUTPUT"
	echo_code end
fi

echo_step "SysBench Memory functions speed test"
echo_code start
sysbench memory run >> "$MY_OUTPUT"
echo_code end

#####################################################################
# Run UnixBench
#####################################################################

echo_line
echo " Now let's run the good old UnixBench. This takes a while."
echo_line
echo_title "UnixBench"
echo_code start
perl "$MY_DIR/UnixBench/Run" -c "1" -c "$MY_CPU_COUNT" >> "$MY_OUTPUT" 2>&1
echo_code end


#####################################################################
# Run Geekbench 5
#####################################################################

echo_line
echo "Now let's run Geekbench 5. This takes a little longer."
echo_line

echo_title "Geekbench 5"
echo_code start
if [[ $MY_GEEKBENCH_NO_UPLOAD ]]; then
	"$MY_DIR/geekbench5" --no-upload >> "$MY_OUTPUT" 2>&1
else
	"$MY_DIR/geekbench5" --upload >> "$MY_OUTPUT" 2>&1
fi
echo_code end


#####################################################################
# Get uptime and load average
#     http://en.wikipedia.org/wiki/Load_%28computing%29
#####################################################################

echo_title "Uptime (Load Average)"
echo_code start
uptime >> "$MY_OUTPUT" 2>&1
echo_code end


#####################################################################
# Calculate the complete duration (runtime)
#####################################################################

echo_title "Complete Duration"
MY_TIMESTAMP_END=$(date "+%s")
MY_DURATION_SEC=$((MY_TIMESTAMP_END-MY_TIMESTAMP_START))
MY_DURATION_MIN=$((MY_DURATION_SEC/60))
{
	echo    "<ul>"
	echo    "    <li>Start: $MY_TIMESTAMP_START</li>"
	echo    "    <li>End: $MY_TIMESTAMP_END</li>"
	echo -n "    <li><b>Duration: "; printf "%.0f sec / %.2f min" "$MY_DURATION_SEC" "$MY_DURATION_MIN"; echo "</b></li>"
	echo    "</ul>"
} >> "$MY_OUTPUT"


#####################################################################
# EOF
#####################################################################

{
	echo "<hr>"
	echo "$ME - $MY_DATE_TIME"
	echo "</html>"
} >> "$MY_OUTPUT"


#####################################################################
# Create gist
#####################################################################

if [[ $MY_GITHUB_API_TOKEN ]]; then
	echo " > Create new gist with HTML results"
	MY_OUTPUT_CONTENT=$(sed -e 's/\r//' -e's/\t/\\t/g' -e 's/"/\\"/g' "$MY_OUTPUT" | awk '{ printf($0 "\\n") }')
	MY_GIST_CONCENT="{\"description\":\"benchmark.sh output\",\"public\":false,\"files\":{\"$MY_TIMESTAMP_START.html\":{\"content\":\"$MY_OUTPUT_CONTENT\"}}}"
	echo "$MY_GIST_CONCENT" > "$MY_GITHUB_API_JSON"
	if curl -X POST -H "Authorization: token $MY_GITHUB_API_TOKEN" -d @"$MY_GITHUB_API_JSON" "https://api.github.com/gists" >> "$MY_GITHUB_API_LOG" 2>&1; then
		echo "    > Upload successful"
	else
		echo "    > Upload failed"
	fi
fi


#####################################################################
# DONE
#####################################################################

echo
echo_line
echo
echo " D O N E"
echo
echo " HTML file for analysis:"
echo "      $MY_OUTPUT"
echo
echo_line
echo
exit 0
