linux-test readme

Building:
 * export CROSS_COMPILE=(something)
 * cd linux-test/
 * make clean
 * make
 * make INSTALLPATH=/full/path/to/rootfs/unit_tests install
   or just 'make install' to install to linux-test/unit_tests

Adding tests:
 * Please don't change the root Makefile and hack your stuff in.
 * Look at some of the Makefiles in subdirectories and use one of them as an
   example of your own Makefile.
 * Your Makefile should support these three targets: clean, all, and install.
   Even if some of these targets don't do anything.
 * Your 'make install' should copy your executables to INSTALLPATH.
 * Please check that running make, make clean, make install in the linux-test
   directory still works after you've added your stuff.
 * Please don't commit any build results to git.  Just scripts and source.
 * After you add your test, add it to the test plan wiki (below).

Test plan:
 * http://sw-wiki.altera.com/twiki/bin/view/Software/HPSLinuxTestPlan

