cat ./soc_system.rbf >/dev/fpga0
echo 1 >/sys/class/fpga-bridge/fpga2hps/enable
echo 1 >/sys/class/fpga-bridge/hps2fpga/enable
echo 1 >/sys/class/fpga-bridge/lwhps2fpga/enable
cat /sys/class/fpga-bridge/fpga2hps/enable
cat /sys/class/fpga-bridge/hps2fpga/enable
cat /sys/class/fpga-bridge/lwhps2fpga/enable
insmod fpga-dma.ko
cat 3ktest.txt >/sys/kernel/debug/fpga_dma/dma
cat /sys/kernel/debug/fpga_dma/dma >doh
diff -qs doh 3ktest.txt
