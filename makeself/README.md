# hibenchmarks static binary build

To build the static binary 64bit distribution package, run:

```bash
$ cd /path/to/hibenchmarks.git
$ ./makeself/build-x86_64-static.sh
```

The program will:
 
1. setup a new docker container with Alpine Linux
2. install the required alpine packages (the build environment, needed libraries, etc)
3. download and compile third party apps that are packaged with hibenchmarks (`bash`, `curl`, etc)
4. compile hibenchmarks
 
Once finished, a file named `hibenchmarks-vX.X.X-gGITHASH-x86_64-DATE-TIME.run` will be created in the current directory. This is the hibenchmarks binary package that can be run to install hibenchmarks on any other computer.

---

## building binaries with debug info

To build hibenchmarks binaries with debugging / tracing information in them, use:

```bash
$ cd /path/to/hibenchmarks.git
$ ./makeself/build-x86_64-static.sh debug
```

These binaries are not optimized (they are a bit slower), they have certain features disables (like log flood protection), other features enables (like `debug flags`) and are not stripped (the binary files are bigger, since they now include source code tracing information).

#### debugging hibenchmarks binaries

Once you have installed a binary package with debugging info, you will need to install `valgrind` and run this command to start hibenchmarks:

```bash
PATH="/opt/hibenchmarks/bin:${PATH}" valgrind --undef-value-errors=no /opt/hibenchmarks/bin/srv/hibenchmarks -D
```

The above command, will run hibenchmarks under `valgrind`. While hibenchmarks runs under `valgrind` it will be 10x slower and use a lot more memory.

If hibenchmarks crashes, `valgrind` will print a stack trace of the issue. Open a github issue to let us know.

To stop hibenchmarks while it runs under `valgrind`, press Control-C on the console.

> If you ommit the parameter `--undef-value-errors=no` to valgrind, you will get hundreds of errors about conditional jumps that depend on unitialized values. This is normal. Valgrind has heuristics to prevent it from printing such errors for system libraries, but for the static hibenchmarks binary, all the required libraries are built into hibenchmarks. So, valgrind cannot appply its heuristics and prints them.
