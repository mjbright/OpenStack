tcpdump -v -i em1 -e "ether host c6:cf:dc:10:00:41" 2>&1 | tee tcpdump.undercloudX.log

# sudo tcpdump -i <network-interface> port 67 or port 68 -e -n

