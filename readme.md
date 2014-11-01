#Using VVV, Wordmove and EasyEngine together
A step by step guide to:

- Configure a local development environment with easy to set up Wordpress installations. 
- Quickly provision staging and production servers, complete with one-line Wordpress installation and configuration.
- Push and pull Wordpress installations, database and all, between local, staging and production environments.
- Optimize and harden Wordpress with very little configuration.

#Local development with VVV and OSX
Use [VVV](https://github.com/Varying-Vagrant-Vagrants/VVV) and [auto-site-setup](https://github.com/joeguilmette/auto-site-setup) to create an easily replicated local development environment with multiple Wordpress installs.

- Follow the instructions over at [VVV](https://github.com/Varying-Vagrant-Vagrants/VVV) to get VirtualBox, Vagrant and VVV going. You can hold off on running `$ vagrant up` for now.
- Use [auto-site-setup](https://github.com/joeguilmette/auto-site-setup) to create new local WordPress installs and to provision your Vagrant box with Wordmove and other useful tools not included in VVV.
	- Create a folder `vvv/www/domain.com/` and add the three files, `vvv-hosts`, `vvv-init.sh` and `vvv-nginx.conf`.
	- Modify each of them to fit your project.
	- Be careful with `vvv-init.sh` and make sure you read it over and edit all the little details. The good news is you can use wp-cli in there to do whatever the fuck you want. You can even do some fun bash stuff, like clone in a theme, or whatever.
	- In `vvv-nginx.conf` I've defaulted to use HHVM. You can comment that line out and switch to php5-fpm if you like.
- If vagrant is up, run `$ vagrant reload --provision`, or just `$ vagrant up --provision` and let it run and it'll create all the sites you've configured.
- It takes 5-10 mins, longer if it's your first time running the script. It'll have to download a few gigs of files.
- Once it's up, you can go to whatever domain you've set in the auto-site-setup files and get going.
- **Congrats on getting your local environment going.**

#Staging and productions servers with Ubuntu and EasyEngine
EasyEngine provides a full Wordpress stack along with one line Wordpress installation and configuration. This guide was written using Ubuntu 14.04, so YMMV with other versions.

##Setting up and securing Ubuntu 14.04x64 on DigitalOcean
- Create a **14.04x64** Droplet.
- Follow the [initai server setup guide](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-14-04).
- [Configure ufw](https://www.digitalocean.com/community/tutorials/how-to-setup-a-firewall-with-ufw-on-an-ubuntu-and-debian-cloud-server).
- [Configure fail2ban](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-fail2ban-on-ubuntu-14-04).
- Run `$ sudo poweroff` and create a Snapshot on Digital Ocean.
- If you use two servers, one for staging and another for production, you can create your second server using this Snapshot to save some time.


##Installing and configuring EasyEngine
- Install EasyEngine `$ wget -qO ee rt.cx/ee && sudo bash ee` and maybe even [RTFM](https://github.com/rtCamp/easyengine).
- Provision your server with`$ sudo ee stack install`.
- Configure the EasyEngine Wordpress defaults in `$ sudo vim /etc/easyengine/ee.conf`. A default username, password, and valid email address are important.

##Creating new Wordpress installations in production
- Create a new site with `$ sudo ee site create domain.com --wpfc`
- Configure DNS over at Digital Ocean.
	- One A record to link domain.com to your server: `A @ 1.1.1.1`.
	- One wildcard CNAME for magical reasons I don't understand: `CNAME * domain.com`.
	- One CNAME per subdomain: `CNAME subdomain domain.com` will link subdomain.domain.com to the server IP listed in your A record.


#Migrating WordPress from one of your local Varying Vagrant Vagrants to your remote Digital Ocean server
Wordmove is the easiest way to automate this process. It is based on Capistrano, and uses rsync to push or pull complete Wordpress installs between two environments with simple commands like `$ wordmove pull --database --environment=staging` or `$ wordmove push --theme --environment=production`. Good stuff.

##Using Wordmove
So it is kind of a pain to get Wordmove to play nice with EasyEngine, only because EasyEngine locks down /var/www pretty well. Nginx is run with the user www-data which can't do much. It does not have a shell, and in fact it should not have one. But in order to use Wordmove, the easiest way is to just give it one.

My solution is to open up www-data, use Wordmove, and then lock down www-data and everything in /var/www.

###Installing Wordmove
My [auto-site-setup](https://github.com/joeguilmette/auto-site-setup) fork has a `pre-provision.sh` file. If you dump it into `vvv/provision` Wordmove will get installed next time you provision vvv. There are some other tools in there as well that you can comment out if you like.

###Configuring www-data to play nice with Wordmove
This is a pretty hacky and possibly insecure way to handle this issue. If you have a better method, let me know.

- Add an alias to give www-data a shell with `$ alias openitup='sudo usermod -s /bin/bash www-data'`. Now by running `$ openitup` www-data has shell access. Run this now.
- Give www-data a password with `$ sudo passwd www-data`
- Create some ssh keys for www-data with `$ su - www-data -c ssh-keygen -t rsa -C "your_email@example.com"`. This is a huge pain in the ass, but it's just permissions. In the end, you should have `/var/www/.ssh` with three files, `authorized_keys`, `id_rsa` and `id_rsa.pub`. Permissions for these files after creation is important, but [my lockdown script](https://github.com/joeguilmette/lockdown) will take care of it.
- Next, run `$ vagrant ssh` from your vvv folder. This will ssh you into the vvv vm you've set up.
- Create some ssh keys in your vagrant box with `$ ssh-keygen -t rsa -C "your_email@example.com"`
- Now you need to send your ssh key from Vagrant to the remote www-data user via `$ cat ~/.ssh/id_rsa.pub | ssh www-data@1.1.1.1 'cat >> .ssh/authorized_keys'`.
- At this point your vagrant box should be able to ssh into www-data@1.1.1.1 without being asked for a password. Give it a shot by running `$ ssh www-data@1.1.1.1` and see if it lets you in without prompting you for a password. If it asks your for a password, exercise that google muscle.


###Configuring Wordmove
- Run `$ wordmove init` in your local WordPress root
- `$ vim Movefile` and edit the local and remote sections appropriately.
- **For SSH, make sure to set user to www-data and keep the password line commented out.**
- Make sure the local absolute path matches the OS that Wordmove is being run from, i.e.:
	- `/var/www/domain.com/wp-core` in Vagrant (locally, I run from here rather than OS X)
	- `~/vvv/www/domain.com/wp-core` in OSX
	- `/srv/www/domain.com/wordpress` in EasyEngine (if you're migrating from staging to production)

###Actually using Wordmove
This assumes that www-data has shell access, your local Movefile is properly configured, you've sent your ssh keys from your local machine to your server at www-data@1.1.1.1 and that the local Wordpress install you're using works.

- Run `$ openitup` on your server to give www-data shell access
- Navigate to the local folder that has your Movefile
- Run `$ wordmove push --all -e=server`. Change `-e=server` to whatever server you've set in your Movefile.
	- If you're getting password prompts from Wordmove while things are pushing **then you need to send your sshkey to your server via `$ cat ~/.ssh/id_rsa.pub | ssh www-data@1.1.1.1 'cat >> .ssh/authorized_keys'`**. If that isn't working, then something is wrong with `/var/www/.ssh/authorized_keys` on your server. Fix it. Otherwise you won't be able to push/pull the db.
- Verify that everything worked
- After Wordmove is done, use [my lockdown script](https://github.com/joeguilmette/lockdown) to close everything up.
 
###Troubleshooting a borked migration

- If you see no changes: 
	- The old site is probably cached, try `$ sudo ee clean all`
	- Maybe you set the wrong root folder. Did you set your Movefile to dump everything in `/var/www/domain.com` instead of `/var/www/domain.com/htdocs`? Dummy. I get to say so because I bork that every. single. time.
	- Maybe the database didn't migrate.
	- Maybe you're using the wrong table prefix. Check wp-config.php
	- Maybe WordPress is looking for a wp-content folder and you moved it
- White screen of death?
	- Could be a database issue.
	- Could also be a table prefix issue.
	- Is wp-content set right?
	- Maybe WordPress doesn't know you changed the domain? See below.
	- Are your DNS settings are properly configured
	- Using HHVM? Maybe it's shitting itself. **Check the HHVM error logs.** HHVM doesn't give you in-browser errors.
		- Not sure if you're using HHVM or not? `$ curl -I domain.com`
	- Maybe Nginx is shitting itself, although if it is, Nginx will give you error message in the browser. But make sure it's happy with your config settings with `$ sudo nginx -t`. Maybe even restart it with `$ sudo service nginx restart`

-Still can't figure it out?
	- Maybe you PEBKAC'd something simple, dummy

##Telling WP the new site url via wp-cli
Sometimes WordPress freaks out when you move it. It stops freaking out after you tell it everything is ok. Only try this stuff if things are broken and you've tried everything else.

```
$ wp option update home 'http://domain.com'
$ wp option update siteurl 'http://domain.com'
```

Or add the following to wp-config.php. I don't like this method as much.

```
define('WP_HOME','http://domain.com');
define('WP_SITEURL','http://domain.com');
```

##Importing a remote database manually
Sometimes you gotta do it...

- Dump the remote db  `$ mysqldump -u username -p remote_db_name > remote_dump.sql`
- Get the remote db `$ scp remote_dump.sql sshuser@host:/path/`
- Import the remote db `$ mysql -u username -p local_db_name < remote_dump.sql`

#Hardening WordPress

##Move wp-config.php back a dir out of the site root
- EasyEngine does this automagically (sorry Adam)...

##Change db prefix
- Easily done via vvv-auto-site-setup and wp-cli during site creation
- Manually specified in wp-config.php

##Change wp-content folder
- Add the following to the top of wp-config.php

```
 define( 'WP_CONTENT_DIR', dirname(__FILE__) . '/wp-content' ); // sometimes this doesn't work
 define( 'WP_CONTENT_DIR', '/var/www/domain.com/htdocs/wp-content'); // and I have to use this
 define( 'WP_CONTENT_URL', 'http://domain.com/wp-content' );
```

##Permissions
The lockdown script should prevent these issues, but just in case... Make sure that all folders in `www/` are set to 755, and all files are set to 644.

`$ find /path/to/www/ -type d -exec chmod 755 {} \;` to 755 all folders

`$ find /path/to/www/ -type f -exec chmod 644 {} \;` to 644 all files.

##Configure ufw, fail2ban and rkhunter
These are important in securing any publicly facing server.

- In `/etc/passwd`, make sure www-data has `/usr/sbin/nologin`, preventing shell access.
- Make sure Nginx, mosh, ssh, ftp and postfix are enabled in `$ sudo vim /etc/fail2ban/jail.local` and `$ sudo ufw status`, and that ufw is in fact enabled along with fail2ban.
- [Configure RKHunter once everything is up and running](https://www.digitalocean.com/community/tutorials/how-to-use-rkhunter-to-guard-against-rootkits-on-an-ubuntu-vps
).

#Optimizing WordPress
There are [some cool resources](https://github.com/davidsonfellipe/awesome-wpo) for getting optimization in Wordpress right. EasyEngine is a great start. If you create sites with the `--wpfc` flag you'll get fast-cgi caching out of the box. And EasyEngine offers some other nifty caching tools to get things going.

Caching aside, you're going to have to execute some PHP eventually. HHVM is crazy good for doing that fast.

##HHVM locally with VVV
- Use [HHVVVM](https://github.com/johnjamesjacoby/hhvvvm) with VVV for HHVM support.
- Mod vvv-nginx.conf to use HHVM in VVV.

##HHVM in production with EasyEngine
**EasyEngine was updated and this guide no longer works.**

HHVM is an insanely fast PHP processor. Generally, I keep both HHVM and php5-fpm installed. HHVM isn't the best at letting you know something is wrong, you pretty much just get a white screen of death. I keep a .conf file in `/etc/nginx/conf.d` that I can include into a site to disable HHVM and use php5-fpm if I think HHVM might be the problem. Usually the only issues I've had are with plugins - HHVM is fully compatible with Wordpress core.

Also I've had issues with wp-cli.

Hopefully HHVM will make it into EasyEngine master soon enough and this will all be replaced with an ee flag.

###Installing HHVM alongside EasyEngine

- Install HHVM

```
$ sudo apt-get update
$ wget -O - http://dl.hhvm.com/conf/hhvm.gpg.key | sudo apt-key add -
$ echo deb http://dl.hhvm.com/ubuntu trusty main | sudo tee /etc/apt/sources.list.d/hhvm.list
$ sudo apt-get update
$ sudo apt-get install hhvm
```

- HHVM has a handy script to plug itself into Nginx `$ sudo /usr/share/hhvm/install_fastcgi.sh`, however EasyEngine has some fastcgi settings that conflict, and you will likely get a `Detected clashing configuration` error.

###Manually hooking HHVM into FastCGI
Wow.

- Step 1
```
$ sudo grep -lr "location ~ .php" . | sudo xargs sed -i -e 's/\.php\$/\\\.\(hh\|php\)\$/g'
$ sudo grep -lr "location ~ \\\\\.php\\$" . | sudo xargs sed -i -e 's/\\\.php\$/\\\.\(hh\|php\)\$/g'
```

- Add `fastcgi_keep_conn on;` inside `/etc/nginx/conf.d/fastcgi.conf`

- Inside `/etc/nginx/hhvm.conf`:

```
location ~ \.(hh|php)$ {  
    fastcgi_keep_conn on;  
    fastcgi_pass   127.0.0.1:8000;  
    fastcgi_index  index.php;  
    fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;  
    include        fastcgi_params;  
} 
```

- Inside `/etc/hhvm/server.ini` change `hhvm.server.port`  to `8000`.

- Near the end of `/etc/hhvm/php.ini` add:

```
hhvm.log.header = true
hhvm.log.natives_stack_trace = true
```

- Delete everything inside `/etc/nginx/conf.d/upstream.conf` and replace with:


```
# Common upstream settings
upstream php {
# server unix:/run/php5-fpm.sock;
server 127.0.0.1:8000;
server 127.0.0.1:9000 backup;
}
upstream debug {
# Debug Pool
server 127.0.0.1:9001;
}
```

- In `/etc/nginx/sites-available/domain.com` add `include hhvm.conf; ` in with the other `include`s.

- Finally, in `/etc/nginx/commong/wpfc.conf` comment out the entire `location ~ \.(hh|php)` block, like so:

```
#location ~ \.(hh|php)$ {  
#       try_files $uri =404;  
#       include fastcgi_params;  
#       fastcgi_pass php;  
#  
#       fastcgi_cache_bypass $skip_cache;  
#       fastcgi_no_cache $skip_cache;  
#  
#       fastcgi_cache WORDPRESS;  
#}  
```

- Now, restart everything.

```
$ sudo service hhvm restart
$ sudo php5-fpm -t && sudo service php5-fpm restart
$ sudo nginx -t && sudo service nginx restart
```

Handy alias for restarting everything: `$ alias rstack='sudo service hhvm restart && sudo php5-fpm -t && sudo service php5-fpm restart && sudo nginx -t && sudo service nginx restart'`

- Last step, verify that you have HHVM up and running. Run `$ curl -I domain.com` and look for `X-Powered-By: HHVM/3.3.1`

- Theoretically this will fallback to php5-fpm when HHVM fails, but I don't know how to test that.

##Enabling a swap file
EasyEngine should handle this for you. If you run into memory issues later, this is a good way out aside from just buying more RAM.

- Create the swapfile `$ fallocate -l 1024M /swapfile`.

- Set those perms `$ sudo chmod 600 /swapfile && mkswap /swapfile`.

- Start the swap `$ swapon /swapfile`.

- Make sure it gets mounted on startup by adding `/swapfile none swap defaults 0 0` on a new line in `$ sudo vim /etc/fstab`