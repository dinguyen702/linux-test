linux-test readme

Building:
 * export CROSS_COMPILE to something in your environment.
 * make clean
 * make
 * make INSTALLPATH=/full/path/to/rootfs/unit_tests install

Adding tests:
 * Please don't change the root Makefile and hack your stuff in.
 * Look at some of the Makefiles in subdirectories and use one
   of them as an example of your own Makefile
 * You should support these three targets: clean, all, and install
   even if some of these targets don't do anything. Makes for cleaner
   make output.
 * Your install should copy your executables to INSTALLPATH

Test plan:
 * http://sw-wiki.altera.com/twiki/bin/view/Software/HPSLinuxTestPlan

