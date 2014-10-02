import getpass
import sys
import telnetlib
import datetime
import time

ipaddr = sys.argv[1]

#print 'Telnet to Netbooter ', ipaddr, ' and cycle port on port ', nbport

# $A4 tells the netbooter to reboot
rebootstr = '$A5 ' + '\r'

tn = telnetlib.Telnet(ipaddr);

tn.read_until('>')
time.sleep(1)

tn.write(rebootstr)

time.sleep(1)

data = ''
while data.find('>') == -1:
	data = tn.read_very_eager()

print data

tn.close()

