# sedutil
## Quickstart
1. Compile sedutil:
	```bash
	autoreconf -i
	./configure
	make -j4
	```
2. Add current dir to `$PATH`:
	```bash
	export PATH=$PATH:$(pwd)
	```
3. Check OPAL support for your drive:
	```
	sedutil-cli --scan
	Scanning for Opal compliant disks
	/dev/nvme0  2  Samsung SSD 960 EVO 250GB                2B7QCXE7
	/dev/sda    2  Crucial_CT250MX200SSD1                   MU04    
	/dev/sdb   12  Samsung SSD 850 EVO 500GB                EMT01B6Q
	/dev/sdc    2  ST500LT025-1DH142                        0001SDM7
	/dev/sdd   12  Samsung SSD 850 EVO 250GB                EMT01B6Q
	No more disks present ending scan
	```
	Verify that your drive has a 2 in the second column indicating OPAL 2 support. If it doesn't  **do not proceed**, there is something that is preventing sedutil from supporting your drive. If you continue you may  **erase all of your data**  
	
4. Create pre-boot authorization (PBA) image:
	```bash
	create-initrd.sh
	create-pba-image.sh
	```
5. Set up the drive:
	```bash
	sedutil-cli --initialsetup <password> <drive>
	sedutil-cli --loadPBAimage <password> pba.disk <drive>
	sedutil-cli --setMBREnable on <password> <drive>
	```
6. Enable locking:
	```bash
	sedutil-cli --enableLockingRange 0 <password> <drive>
	```

## Useful commands
  
* Accessing the drive from a live distro:
	```bash
	sedutil-cli --setlockingrange 0 rw password drive  
	sedutil-cli --setmbrdone on password drive
	partprobe drive
	```
	> libata.allow_tpm must be set to 1 (true) in order to use sedutil. Either add libata.allow_tpm=1 to the kernel parameters, or by setting /sys/module/libata/parameters/allow_tpm to 1 on a running system.  
  
* Disable locking:
	```bash
	sedutil-cli --disableLockingRange 0 password drive
	sedutil-cli --setMBREnable off password drive
	```
* Re-enable locking and the PBA:
	```bash
	sedutil-cli --enableLockingRange 0 password drive  
	sedutil-cli --setMBRDone on password drive  
	sedutil-cli --setMBREnable on password drive
	```
