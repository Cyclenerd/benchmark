# benchmark.sh

Bash Script which runs several Linux benchmarks (Sysbench, UnixBench and Geekbench).
I've tried to keep it simple. You can adjust it quickly.

## Demo Output

https://www.nkn-it.de/benchmark_demo/


## Requirements

* __GNU/Linux__
	* Currently only tested with Ubuntu and Fedora. Should also work with every other Linux distribution and Windows Subsystem for Linux (WSL).
* [Bash](https://www.gnu.org/software/bash/)
* [curl](https://curl.haxx.se/)
* [Make](https://www.gnu.org/software/make/)
* [GCC](https://gcc.gnu.org/install/)
* [Perl](https://www.perl.org/get.html)
* Network tools
	* ifconfig
	* ping
	* traceroute
* PCI Utilities
	* lspci
* [Hardware Lister (lshw)](http://www.ezix.org/project/wiki/HardwareLiSter)
* [dd](https://www.gnu.org/software/coreutils/manual/)
* [IOPing](https://github.com/koct9i/ioping)
* [FIO](https://wiki.mikejung.biz/Benchmarking#Fio_Installation)
* [SysBench](https://github.com/akopytov/sysbench)

These Ubuntu packages should be installed:

```bash
apt-get install     \
	bash            \
	curl            \
	make            \
	gcc             \
	build-essential \
	net-tools       \
	inetutils-ping  \
	traceroute      \
	pciutils        \
	perl            \
	lshw            \
	ioping          \
	fio             \
	sysbench
```

[UnixBench](https://github.com/kdlucas/byte-unixbench) and [Geekbench 5](http://geekbench.com/) are automatically loaded and are temporarily installed.


## Installation

Download:

	curl -f https://raw.githubusercontent.com/Cyclenerd/benchmark/master/benchmark.sh -o benchmark.sh

Alternative download with short URL:

	curl -fL http://bit.ly/benchmark_sh -o benchmark.sh


## Usage

Run as root:

	bash benchmark.sh

Unlock Geekbench using EMAIL and KEY:

	bash benchmark.sh -e <Geekbench license email> -k <Geekbench license key>

Create GitHub gist with HTML results:

	bash benchmark.sh -g <GitHub API token with scope gist>

Help:

	bash benchmark.sh -h


## Program Flow

* Check the requirements
* Download and build UnixBench
* Download Geekbench 5
* Get System info and versions
	* Hostename
	* Complete hardware
	* Kernel
	* Make
	* GCC
* Run bandwidth benchmarks
	* ping
	* traceroute
	* 100 MB download with curl
* Run I/O benchmarks
	* dd
	* IOPing
	* FIO
* Run SysBench
	* CPU
* Run UnixBench
	* The complete program! This takes a little longer.
* Run Geekbench 5
	* CPU
* Get uptime and load average
* Calculate the complete duration (runtime)

## ⚠️ Attention

This script generates a lot of load. Be aware of this. So you should just use the computer alone. Use at your own risk.

## License

GNU Public License version 3.
Please feel free to fork and modify this on GitHub (https://github.com/Cyclenerd/benchmark).