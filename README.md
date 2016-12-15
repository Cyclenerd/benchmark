# benchmark.sh

Bash Script which runs several Linux benchmarks (Sysbench, UnixBench and Geekbench).
I've tried to keep it simple. You can adjust it quickly.

With my other scripts you can [automate the installation](https://github.com/Cyclenerd/postinstall) and upload the result to [Pastebin](https://github.com/Cyclenerd/pastebin-shell). You can easily automate the complete benchmark.


## Demo Output

https://cyclenerd.github.io/benchmark_demo/


## Requirements

* __GNU/Linux__
	* Currently only tested with Ubuntu and Fedora. Should also work with every other Linux distribution.
* [Bash](https://www.gnu.org/software/bash/)
* [curl](https://curl.haxx.se/)
* [Make](https://www.gnu.org/software/make/)
* [GCC](https://gcc.gnu.org/install/)
* [Perl](https://www.perl.org/get.html)
* Network tools
	* ifconfig
	* ping
	* traceroute
* [Hardware Lister (lshw)](http://www.ezix.org/project/wiki/HardwareLiSter)
* [dd](https://www.gnu.org/software/coreutils/manual/)
* [IOPing](https://github.com/koct9i/ioping)
* [FIO](https://wiki.mikejung.biz/Benchmarking#Fio_Installation)
* [SysBench](https://github.com/akopytov/sysbench)

These Ubuntu packages should be installed:

	apt-get install bash curl make gcc build-essential net-tools traceroute perl lshw ioping fio sysbench

[UnixBench](https://github.com/kdlucas/byte-unixbench) and [Geekbench 4](http://geekbench.com/) are automatically loaded and are temporarily installed.


## Installation

Download:

	curl -f https://raw.githubusercontent.com/Cyclenerd/benchmark/master/benchmark.sh -o benchmark.sh


## Usage

Run as root:

	bash benchmark.sh

Example including upload to Pastebin:

	bash benchmark.sh && pbin -n "Acer A0756" -f "html5" -l < "/root/benchmark/output.html"

You can get `pbin` here: https://github.com/Cyclenerd/pastebin-shell 


## Program Flow

* Check the requirements
* Download and build UnixBench
* Download Geekbench 4
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
* Run Geekbench 4
	* Mainly CPU and graphics
	* Ideal for your boss: Value is comparable to Geekbench from the iPhone 😉
* Get uptime and load average
* Calculate the complete duration (runtime)

## ⚠️ Attention

This script generates a lot of load. Be aware of this. So you should just use the computer alone. Use at your own risk.

## License

GNU Public License version 3.
Please feel free to fork and modify this on GitHub (https://github.com/Cyclenerd/benchmark).