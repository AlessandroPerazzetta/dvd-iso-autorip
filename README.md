# DVD-ISO-AutoRip 
Based on [ThisIsTenou/bluray-iso-autorip](https://github.com/ThisIsTenou/bluray-iso-autorip)

A bash script for automatically creating ISOs from any kind of data disc (like DVDs, BluRays or file discs).
It has been written with the focus on parallelization, so that you can rip from multiple drives at once.

Disks will automatically be ejected once they're finished and newly inserted disks will automatically be ripped with the predefined, global parameters in the settings.cfg file.

# Disclaimer
This script has only been tested on Ubuntu 20.04.01. Whilst it might work with other systems, I can't guarantee for it.

2023-10-11: Tested on arch based distro (yay package manager)

# Installation:
This script depends on some external packages.
You can ensure they're installed and on the latest version by running this command:
`sudo apt update && sudo apt install fprintd setcd sed util-linux coreutils udisks2`

Download the scripts and setting file to a directory of your choice and make the scripts executable (`chmod +x isorip.sh wrapper.sh`).
Don't forget to adjust the settings.cfg file to your liking.
Then, just run the wrapper and you're good to go: `bash wrapper.sh`

Happy ripping!

# Note
If you just want to rip a single disc, you can call the autorip.sh-script directly by passing the drive's location as an argument: `bash isorip.sh /dev/sr0`.
This will rip the disc the same way as with the wrapper, but just once, without all the sweet automation.


# Additions from original version:
- New filename suffix switch based on args, (default) numeric autoincrement indexing if file exist, or date time:

    - Index trigger:
        - `bash wrapper.sh [index||none]`
        - `bash isorip.sh /dev/sr0 [index||none]`

    - Date trigger:
        - `bash wrapper.sh date`
        - `bash isorip.sh /dev/sr0 date`

- Support for multiple Linux distro and MacOS package manager