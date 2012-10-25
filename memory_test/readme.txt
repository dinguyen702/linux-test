Testing SDRAM

---------
contents:
---------
 * readme.txt  : You're reading it now!
 * memtester   : Source for the memtester app from http://pyropus.ca/software/memtester/

---------
memtester
---------
 I changed the 'conf-cc' and 'conf-ld' files to use CROSS_COMPILE. Assuming that
 you have that defined in your environment, you should be able to just type:
   $ cd memtester
   $ make
 and it will build.  Do 'file' on the built memtester file to make sure it is an
 ARM executible.  If you have problems, further compilation instructions are in the
 memtester/README

 To run, put it in your rootfs under /bin and boot your board.  Usage is:
   memtester [size] [iterations]
 where iterations defaults to infinity.  I've run (on vt): 'memtester 1M 1'
 It will do a pretty exhaustive set of tests, looking for stuck bits, etc.

 To speed up testing, you can select which tests by setting the MEMTESTER_TEST_MASK
 environment variable, for example:

   $ MEMTESTER_TEST_MASK=1 memtester 64K 1

 This is a bitmask, so setting it to 1 selects only the 'Random Value' test.
 Note that some tests assume that test #1 has been run to initize the values in ram.
 From memtest/memtest.c with my comments of the bit mask values:

struct test tests[] = {
    { "Random Value", test_random_value },                // 0x00000001
    { "Compare XOR", test_xor_comparison },               // 0x00000002 = requires init by Random Value Test
    { "Compare SUB", test_sub_comparison },               // 0x00000004 = requires init by Random Value Test
    { "Compare MUL", test_mul_comparison },               // 0x00000008 = requires init by Random Value Test
    { "Compare DIV",test_div_comparison },                // 0x00000010 = requires init by Random Value Test
    { "Compare OR", test_or_comparison },                 // 0x00000020 = requires init by Random Value Test
    { "Compare AND", test_and_comparison },               // 0x00000040 = requires init by Random Value Test
    { "Sequential Increment", test_seqinc_comparison },   // 0x00000080
    { "Solid Bits", test_solidbits_comparison },          // 0x00000100
    { "Block Sequential", test_blockseq_comparison },     // 0x00000200
    { "Checkerboard", test_checkerboard_comparison },     // 0x00000400
    { "Bit Spread", test_bitspread_comparison },          // 0x00000800
    { "Bit Flip", test_bitflip_comparison },              // 0x00001000
    { "Walking Ones", test_walkbits1_comparison },        // 0x00002000
    { "Walking Zeroes", test_walkbits0_comparison },      // 0x00004000
#ifdef TEST_NARROW_WRITES
    { "8-bit Writes", test_8bit_wide_random },            // 0x00008000
    { "16-bit Writes", test_16bit_wide_random },          // 0x00010000
#endif
    { NULL, NULL }
};


