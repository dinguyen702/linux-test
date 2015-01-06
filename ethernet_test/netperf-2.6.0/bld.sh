echo "ac_cv_func_setpgrp_void=yes" > config.cache
./configure CC=${CROSS_COMPILE}gcc LD=${CROSS_COMPILE}ld --host=i386 --config-cache 
make 

