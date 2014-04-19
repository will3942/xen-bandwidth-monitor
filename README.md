xen-bandwidth-monitor
=====================

A bandwidth monitor, null router and alerter for the Xen bare metal hypervisor  

## Dependencies  

MongoDB to store all the history and XM as the Xen toolstack.  


## Usage  

1.  `bundle install` install necessary dependencies.  
2.  Edit `bwmon.rb` lines 101, 110 and 112 to your own email address, domain and subject respectively.  
3.  `ruby addvm.rb` Add all your VMs with their hostnames (must be the same as `xm list` and their config file).  
4.  `./install.sh` Move the necessary scripts in place.
5.  Edit your crontab (`crontab -e`) to run `bash /path/to/start.sh` at your specified interval.  
6.  The monitor will then run the script at that interval and email you and nullroute the VM if it goes over its bandwidth allocation.

## License

Copyright (c) 2014 Defined Code Ltd. See the LICENSE file for license rights and limitations (MIT).

## Contact

You can contact me [@Will3942](http://twitter.com/will3942) or [will@will3942.com](mailto:will@will3942.com)
