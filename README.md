# Wordpress boilerplate
This boilerplate creates a _ready to use_ environment for develop wordpress themes and plugins.  
Keep in mind, this project doesn't provide any Wordpress instance, you've to [download and install](//wordpress.org/download/) in web/dev/ path, create a folder named wordpress inside. That's it!    
It uses [Vagrant](//vagrantup.org) and [VirtualBox](//virtualbox.org) to provision the environment to local system. 

## Requirements
* Vagrant, [download](https://www.vagrantup.com/downloads.html) and [install](https://www.vagrantup.com/docs/installation/)
* VirtualBox, [download and install](https://www.vagrantup.com/docs/installation/)

## Environment variables
Wordpress boilerplate comes with default parameters.  
Below I list all the variables that you may customize accordling to your needs.
In Vagratfile you'll find more variables, someone is unmodifiable.

### Postfix
```bash
OEMAIL=youremail@domain.tld  
AEMAIL=alert@domain.tld  
DOMAIN=dev.local  
MAILER="Satellite system"  
RELAYHOST=smtp.domain.tld  
EPSW=YOUR-PASSWORD
```

### Ports / IP
```bash
SSHPORT=22
HTTPPORT=8080  
HTTPSPORT=8043
DBPORT=3306
IP=192.168.10.10
```

### Time zone
Update this values selecting your preferred time zone.  
Here you'll find a [complete list of available timezones.](//en.wikipedia.org/wiki/List_of_tz_database_time_zones")  
```bash
TZDATA="Europe/Rome"
```

### MariaDB users
Here you may manage username and password for:
1. Super user. It's a remote user, helpful by connecting to database via client (MySQL Workbench)
2. User. It's a local user with a restricted permission

#### Database users
```bash
DBROOTPSW=rootpass  

DBSUSER=super  
DBSPSW=superpass

DBLUSER=user  
DBLPSW=userpass
```

#### Database name
```bash
DBNAME=wpdev
```

## How it works
Wordpress boilerplate is provided _out-of-the box_ with:

* Ubuntu 18.04 LTS (Bionic Beaver) [release details](//releases.ubuntu.com/18.04/), [vagrant box](//app.vagrantup.com/ubuntu/boxes/bionic64)
* NTP
* PHP7.2
* OpenSSL
* NginX
* MariaDB 10.2
* Postfix

### Setup your Virtual Machine
Wordpress boilerplate uses _as is_ 1 GB of RAM memory.  
You could increase, decrease, change VM name as you prefer by editing *Vagrantfile*

### Create your environment
Download this project in your project folder, open your terminal, then run:

```bash
vagrant provision
```

At first time this command creates virtualmachine using VirtualBox as provisioning system.
VirtualBox runs in background, you don't need to do anithing.

### Check your installations
You have to update your hosts file, depending on your OS, dd this line at the bottom:

```bash
192.168.10.10 dev.local dev-wp.local
```

Linux and MacOS, update /etc/hosts  
Windows, update %WinDir%\System32\Drivers\Etc

After installation completed visit:  
* visit https://dev.local:8043/ to check your PHP details
* visit https://dev-wp.local:8043/wp-admin to view your Wordpress backend
* visit https://dev-wp.local:8043/ to view your website

### Start and stop your environment
Run up your environmet.

```bash
vagrant up
```

Stop your environmet.

```bash
vagrant halt
```

### Destroy your environment
Sometimes you could need to destroy your environmet and provision new one.
*Be Carefull, this command destroy machine and data stored in database*

```bash
vagrant destroy
```

You have to confirm it by pressing 'Y'

