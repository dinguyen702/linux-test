

foreach spd [list 10 100 1000] {
   foreach dp [list half full] {
   puts "spd $spd dp $dp\r"
   }
}

foreach adv [list 0x2f 0xf 0xe 0xd 0xc 0xb 0xa 0x9 0x8 0x7 0x6 0x5 0x4 0x3 0x2 0x1] \
	exps [list 1000 100 100 100 100 100 100 100 100 100 100 100 100 10 10 10] \
        expd [list 1 1 1 1 1 1 1 1 1 0 0 0 0 1 1 0 ] {

    puts "adv $adv exps $exps expd $expd\r"
}
#
