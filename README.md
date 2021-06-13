CoWFC Installer
======

This script installs the CoWFC front-end and back-end from https://github.com/EnergyCube/CoWFC

✅ Support Ubuntu 14.04 & 16.04

✅ Support Debian 10 (❌ LAN Reported not working ! Only tested on a VPS using a domain name)

🔨 Contributing
-------

Please open pull requests.

🔧 Error reporting
-------

Create a new issue and communicate all informations that you can.

📝 How to use
-------

![image](https://upload.wikimedia.org/wikipedia/commons/thumb/9/9d/Ubuntu_logo.svg/100px-Ubuntu_logo.svg.png)

`mkdir /var/www ; cd /var/www && wget https://raw.githubusercontent.com/EnergyCube/cowfc_installer/master/cowfc.sh && chmod +x cowfc.sh && ./cowfc.sh`

After system reboot : `cd /var/www && ./cowfc.sh`

![image](https://www.debian.org/logos/openlogo-nd-25.png) Debian
----

`wget https://raw.githubusercontent.com/EnergyCube/cowfc_installer/master/cowfc-debian.sh && chmod +x cowfc-debian.sh && ./cowfc-debian.sh`

📖 Notes
-------

This script comes in 3 phases for Ubuntu. Each phase involves a reboot
-	Add the PHP 7.1 repo
-	Continue CoWFC install
-	Reboot after CoWFC install

This script comes in 1 phases for Debian.
-	Install CoWFC & Reboot

Ubuntu script use PHP 7.1 & MySQL<br/>
Debian script use PHP 7.4 & MariaDB<br/>
AWS Ubuntu 16 script use PHP 7.0 & MySQL

❤️ Credits
-------
kyle95wm
