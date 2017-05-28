echo -e "--- ### ----------------------------------------------------------------------------------- ### ---"
echo -e "--- ### This script installs necessary packages for Silverstripe development,               ### ---"
echo -e "--- ### on a Vagrant / VirtualBox machine, and adapted from                                 ### ---"
echo -e "--- ### http://silverstripe-webdevelopment.com/tricks/creating-a-development-machine/, and  ### ---"
echo -e "--- ### https://gist.github.com/rrosiek/8190550.                                            ### ---"
echo -e "--- ###                                                                                     ### ---"
echo -e "--- ### This set-up is based on a Vagrant box running Ubuntu 16.04, with a L.A.M.P stack.   ### ---"
echo -e "--- ### The particular Vagrant box used with this set-up can be found at                    ### ---"
echo -e "--- ### https://atlas.hashicorp.com/ubuntu/boxes/xenial64.                                  ### ---"
echo -e "--- ### ----------------------------------------------------------------------------------- ### ---\n"

echo -e "Ok, lets begin setting up our server...\n\n"

echo -e "Check to see if our machine has already been set-up...\n"

if [ ! -f "/root/provisioned" ]; then

    echo -e "Set system timezone to 'Pacific/Auckland'.\n"
    sudo timedatectl set-timezone Pacific/Auckland

    DATE_STARTED=$(date)
    # Replace email with your own.
    DEVELOPER_EMAIL_ADDRESS=youremail@example.com
    echo -e "SCRIPT INSTALL STARTED AT $DATE_STARTED.\n"

    echo -e "Truncate build log (/vagrant/vm_build.log).\n"
    sudo echo "" > /vagrant/vm_build.log

    echo -e "Initialize SSH, if not already done.\n"
    sudo touch ~/.ssh/config
    sudo ssh-keygen -t rsa -b 4096 -C "[ubuntu]" >> /vagrant/vm_build.log 2>&1

    echo -e "Lets update our packages list, and currently installed packages...\n"
    sudo apt-get update && sudo apt-get -y upgrade && sudo apt-get -y dist-upgrade >> /vagrant/vm_build.log 2>&1

    echo -e "Install base packages, if not already installed.\n"
    sudo apt-get -y install vim curl build-essential python-software-properties git zip unzip >> /vagrant/vm_build.log 2>&1

    echo -e "Set-up initial default Git configuration.\n"
    sudo git config --global core.filemode false >> /vagrant/vm_build.log 2>&1 

    echo -e "Install subversion (SVN).\n"
    sudo apt-get -y install subversion >> /vagrant/vm_build.log 2>&1

    echo -e "Install and set-up PHP5.6 (downgrade to PHP 5.6, if PHP already installed).\n"
    sudo apt-get purge `dpkg -l | grep php| awk '{print $2}' |tr "\n" " "` >> /vagrant/vm_build.log 2>&1
    sudo add-apt-repository ppa:ondrej/php >> /vagrant/vm_build.log 2>&1
    sudo apt-get update >> /vagrant/vm_build.log 2>&1 
    sudo apt-get -y install php5.6 >> /vagrant/vm_build.log 2>&1

    echo -e "Install necessary PHP modules.\n"
    sudo apt-get -y install libapache2-mod-php5.6 php5.6-mcrypt php5.6-tidy php5.6-gd php5.6-curl php5.6-zip php5.6-mbstring php5.6-dom php5.6-cli php5.6-json php5.6-common php5.6-opcache php5.6-readline php5.6-xml php5.6-mysql >> /vagrant/vm_build.log 2>&1 

    echo -e "Enable PHP5.6 modules, if not enabled by default.\n"
    sudo phpenmod -v php5.6 mcrypt tidy gd curl zip mbstring dom cli json common opcache readline xml mysql >> /vagrant/vm_build.log 2>&1

    echo -e "Set-up PHP timezone (to 'Pacific/Auckland').\n"
    sudo chown ubuntu:root /etc/php/5.6/apache2/php.ini
    sudo echo "date.timezone = Pacific/Auckland" >> /etc/php/5.6/apache2/php.ini
    sudo chown root:root /etc/php/5.6/apache2/php.ini
    sudo chown ubuntu:root /etc/php/5.6/cli/php.ini
    sudo echo "date.timezone = Pacific/Auckland" >> /etc/php/5.6/cli/php.ini
    sudo chown root:root /etc/php/5.6/cli/php.ini

    echo -e "Install Apache server.\n"
    sudo apt-get -y install apache2 >> /vagrant/vm_build.log 2>&1

    echo -e "Set-up / enable Apache modules.\n"
    sudo a2enmod rewrite >> /vagrant/vm_build.log 2>&1
    sudo a2enmod vhost_alias >> /vagrant/vm_build.log 2>&1
    sudo a2enmod authz_core >> /vagrant/vm_build.log 2>&1
    sudo a2enmod authz_dbd >> /vagrant/vm_build.log 2>&1
    sudo service apache2 restart >> /vagrant/vm_build.log 2>&1

    echo -e "Set-up MySQL and phpMyAdmin (for development purposes ONLY).\n"
    DBHOST=localhost
    DBUSER=ubuntu
    DBPASSWD=ubuntu
    debconf-set-selections <<< "mysql-server mysql-server/root_password password $DBPASSWD"
    debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DBPASSWD"
    debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
    debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWD"
    debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWD"
    debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWD"
    debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none"
    sudo apt-get -y install mysql-server phpmyadmin >> /vagrant/vm_build.log 2>&1

    echo -e "Set-up Apache server default.\n"
    echo -e "This will show system information with phpinfo() /var/www/server-default/index.php.\n"
    sudo mkdir /var/www/server-default  >> /vagrant/vm_build.log 2>&1
    sudo touch /var/www/server-default/index.php 
    sudo echo "<?php phpinfo();" > /var/www/server-default/index.php

    echo -e "Set-up default sites-enabled for Apache.\n\n"

    echo -e "--- ### ------------------------------------------------------------------------ ### ---"
    echo -e "--- ### DO NOT ENABLE 'server-default.localhost' SITE ON A PRODUCTION SERVER !!! ### ---"
    echo -e "--- ### THIS WILL HAVE **SEVERE** SECURITY IMPLICATIONS !!!                      ### ---"
    echo -e "--- ### THE SAME IDEALLY GOES FOR 'phpmyadmin.localhost' AS WELL !!!             ### ---"
    echo -e "--- ### ------------------------------------------------------------------------ ### ---\n\n"

    sudo echo "<VirtualHost *:80>
        ServerName phpmyadmin.localhost
        ServerAlias phpmyadmin.localhost
        DocumentRoot /usr/share/phpmyadmin
        <Directory /usr/share/phpmyadmin>
        Options FollowSymLinks
        DirectoryIndex index.php
        <IfModule mod_php.c>
            <IfModule mod_mime.c>
                AddType application/x-httpd-php .php
            </IfModule>
            <FilesMatch ".+\.php$">
                SetHandler application/x-httpd-php
            </FilesMatch>
            php_flag magic_quotes_gpc Off
            php_flag track_vars On
            php_flag register_globals Off
            php_admin_flag allow_url_fopen On
            php_value include_path .
            php_admin_value upload_tmp_dir /var/lib/phpmyadmin/tmp
            php_admin_value open_basedir /usr/share/phpmyadmin/:/etc/phpmyadmin/:/var/lib/phpmyadmin/:/usr/share/php/php-gettext/:/usr/share/javascript/:/usr/share/php/tcpdf/:/usr/share/doc/phpmyadmin/:/usr/share/php/phpseclib/
        </IfModule>
        </Directory>

        # Authorize for setup
        <Directory /usr/share/phpmyadmin/setup>
            <IfModule mod_authz_core.c>
                <IfModule mod_authn_file.c>
                    AuthType Basic
                    AuthName \"phpMyAdmin Setup\"
                    AuthUserFile /etc/phpmyadmin/htpasswd.setup
                </IfModule>
                Require valid-user
            </IfModule>
        </Directory>

        # Disallow web access to directories that don't need it
        <Directory /usr/share/phpmyadmin/libraries>
            Require all denied
        </Directory>
        <Directory /usr/share/phpmyadmin/setup/lib>
            Require all denied
        </Directory>
    </VirtualHost>

    <VirtualHost *:80>
        ServerName server-default.localhost
        ServerAlias server-default.localhost
        DocumentRoot /var/www/server-default
        <Directory /usr/share/phpmyadmin>
            Options FollowSymLinks
            DirectoryIndex index.php
        </Directory>        
    </VirtualHost>

    <VirtualHost *:80>
        ServerName localhost
        ServerAlias localhost *.localhost
        ServerAdmin webmaster@localhost

        DocumentRoot /var/www
        VirtualDocumentRoot /var/www/%-2+/

        <Directory />
            Options FollowSymLinks
            AllowOverride None
        </Directory>

        <Directory /var/www >
            Options Indexes FollowSymLinks MultiViews
            AllowOverride All
            Order allow,deny
            allow from all
            RewriteEngine On
            RewriteBase /
            SetEnv HTTP_MOD_REWRITE On
            RewriteEngine On
            RewriteCond %{REQUEST_URI} ^(.*)$
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteRule .* sapphire/main.php?url=%1 [QSA]

            RewriteCond %{REQUEST_URI} ^(.*)/sapphire/main.php$
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteRule .* framework/main.php?url=%1 [QSA]
        </Directory>

        ErrorLog ${APACHE_LOG_DIR}/error.log
        LogLevel debug
        
    </VirtualHost>" > /etc/apache2/sites-enabled/000-default.conf 
    sudo service apache2 restart >> /vagrant/vm_build.log 2>&1

    echo -e "Installing Composer, globally, for PHP package management.\n"
    curl -sS https://getcomposer.org/installer | php >> /vagrant/vm_build.log 2>&1
    sudo mv composer.phar /usr/local/bin/composer >> /vagrant/vm_build.log 2>&1
    
    echo -e "Remove Silverstripe test project, if it already exists.\n"
    if [ -d "/var/www/test" ]; then 
        sudo chown -R ubuntu:ubuntu /var/www/test
        sudo chmod -R 777 /var/www/test
        rm -rf /var/www/test /vagrant/vm_build.log 2>&1 
    fi

    echo -e "Set-up database for Silverstripe test site."
    SILVERSTRIPE_TEST_DB=SS_test
    mysql -uroot -p$DBPASSWD -e "DROP DATABASE IF EXISTS $SILVERSTRIPE_TEST_DB" >> /vagrant/vm_build.log 2>&1
    mysql -uroot -p$DBPASSWD -e "CREATE DATABASE IF NOT EXISTS $SILVERSTRIPE_TEST_DB" >> /vagrant/vm_build.log 2>&1
    mysql -uroot -p$DBPASSWD -e "GRANT ALL PRIVILEGES ON $SILVERSTRIPE_TEST_DB.* TO '$DBUSER'@'localhost' IDENTIFIED BY '$DBPASSWD'" > /vagrant/vm_build.log 2>&1
    mysql -uroot -p$DBPASSWD -e "FLUSH PRIVILEGES" >> /vagrant/vm_build.log 2>&1

    echo -e "Remove Silverstripe default configuration file, if it exists."
    if [ -f "/var/www/_ss_environment.php" ]; then 
        rm /var/www/_ss_environment.php /vagrant/vm_build.log 2>&1 
    fi
    
    echo -e "Set-up Silverstripe default configuration file (/var/www/_ss_environment.php)."
    touch /var/www/_ss_environment.php
    
    echo "<?php
        define('SS_DATABASE_SERVER','localhost');
        define('SS_DATABASE_USERNAME','root');
        define('SS_DATABASE_PASSWORD','$DBPASSWD');
        define('SS_ENVIRONMENT_TYPE','dev');
        define('SS_DATABASE_CHOOSE_NAME', true);
        define('SS_DEFAULT_ADMIN_USERNAME','admin');
        define('SS_DEFAULT_ADMIN_PASSWORD','admin');
        define('SS_SEND_ALL_EMAILS_TO','$DEVELOPER_EMAIL_ADDRESS');" > /var/www/_ss_environment.php
    sudo chown ubuntu:www-data /var/www/_ss_environment.php
    sudo chmod 0644 /var/www/_ss_environment.php

    echo -e "Create test Silverstripe site.\n"
    sudo chown ubuntu:www-data /var/www/ -R >> /vagrant/vm_build.log 2>&1
    cd /var/www/ >> /vagrant/vm_build.log 2>&1
    composer create-project silverstripe/installer test 3.5.3 >> /vagrant/vm_build.log 2>&1
    cd test >> /vagrant/vm_build.log 2>&1
    chmod -R 0777 * >> /vagrant/vm_build.log 2>&1

    echo -e "Leaving Silverstripe test project directory (/var/www/test), going into /home/ubuntu...\n"
    cd /home/ubuntu >> /vagrant/vm_build.log 2>&1 

    echo -e "Set-up / install PHPDox.\n"
    wget https://github.com/theseer/phpdox/releases/download/0.9.0/phpdox-0.9.0.phar  >> /vagrant/vm_build.log 2>&1
    chmod +x phpdox-0.9.0.phar >> /vagrant/vm_build.log 2>&1
    sudo mv phpdox-0.9.0.phar /usr/local/bin/phpdox >> /vagrant/vm_build.log 2>&1

    echo -e "Set-up / install PHP-CS-Fixer.\n"
    wget https://github.com/FriendsOfPHP/PHP-CS-Fixer/releases/download/v2.3.2/php-cs-fixer.phar -O php-cs-fixer >> /vagrant/vm_build.log 2>&1
    sudo chmod a+x php-cs-fixer >> /vagrant/vm_build.log 2>&1
    sudo mv php-cs-fixer /usr/local/bin/php-cs-fixer >> /vagrant/vm_build.log 2>&1

    echo -e "Add Node 6.10.3 (for Bower, Grunt, NPM, etc).\n"
    curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash - >> /vagrant/vm_build.log 2>&1 
    sudo apt-get update >> /vagrant/vm_build.log 2>&1 

    echo -e "Installing NodeJS and NPM.\n"
    sudo apt-get -y install nodejs >> /vagrant/vm_build.log 2>&1

    echo -e "Installing Gulp and Bower.\n\n"
    npm install -g gulp bower >> /vagrant/vm_build.log 2>&1

    echo -e "--- ### ------------------------------------------------------------------------------------------------------- ### ---"
    echo -e "--- ### Creating user 'silverstripedev' for SFTP.                                                               ### ---"
    echo -e "--- ### NOTE: DO NOT SET PASSWORD THIS WAY ON PRODUCTION MACHINE!!!                                             ### ---"
    echo -e "--- ### NOTE: THIS IS FOR DEVELOPMENT PURPOSES ONLY!!!                                                          ### ---"
    echo -e "--- ### ------------------------------------------------------------------------------------------------------- ### ---\n"
    sudo useradd -u 74583 -p $(echo silverstripe | openssl passwd -1 -stdin) -m silverstripedev >> /vagrant/vm_build.log 2>&1
    sudo chown -R silverstripedev:www-data /var/www >> /vagrant/vm_build.log 2>&1
    sudo usermod -d /var/www silverstripedev >> /vagrant/vm_build.log 2>&1
    echo -e "SFTP user 'silverstripedev' with password 'silverstripe' created."
    echo -e "When SFTP'ing into server as this user, you will automatically ."
    echo -e "go into /var/www directory.\n"
    
    if [ ! -f "/root/provisioned" ]; then 
        echo -e "Now the set-up has finished, create a file to show that the machine has been 'provisioned'."
        sudo touch /root/provisioned 
        sudo chmod a-w /root/provisioned    
    fi
    
    echo -e "SCRIPT INSTALL STARTED AT $DATE_STARTED.\n"
    DATE_FINISHED=$(date)
    echo -e "SCRIPT INSTALL FINISHED AT $DATE_FINISHED.\n\n"

    echo -e "--- ### ---------------------------------------------------------------------------------------------------------------- ### ---"
    echo -e "--- ### Put these entries in your Windows (the host O.S) hosts file, e.g. C:\ Windows \ System32 \ drivers \ etc \ hosts ### ---"
    echo -e "--- ###                                                                                                                  ### ---"
    echo -e "--- ### 127.0.0.1:8080                   localhost                                                                       ### ---"
    echo -e "--- ### 127.0.0.1:8080/phpmyadmin/       phpmyadmin.localhost                                                            ### ---"
    echo -e "--- ### 127.0.0.1:8080                   server-default.localhost                                                        ### ---"
    echo -e "--- ###                                                                                                                  ### ---"
    echo -e "--- ### Note: if you are using a Linux-based O.S as your host O.S, put the above entries in /etc/hosts                   ### ---"
    echo -e "--- ###                                                                                                                  ### ---"
    echo -e "--- ### For the site's defined above, you can access them in your browser as follows:                                    ### ---"
    echo -e "--- ###                                                                                                                  ### ---"
    echo -e "--- ### Silverstripe Test => http://test.localhost:8080                                                                  ### ---"
    echo -e "--- ### phpMyAdmin => http://phpmyadmin.localhost:8080                                                                   ### ---"
    echo -e "--- ### Server Default => http://server-default.localhost:8080                                                           ### ---"
    echo -e "--- ###                                                                                                                  ### ---"
    echo -e "--- ### Note: the 'Server Default' site displays PHP/System information.                                                 ### ---"
    echo -e "--- ###                                                                                                                  ### ---"
    echo -e "--- ### DO NOT ENABLE THE ABOVE SERVER DEFAULT SITE ON A PRODUCTION SERVER !!!                                           ### ---"
    echo -e "--- ### THAT WILL HAVE **SEVERE** SECURITY IMPLICATIONS !!!                                                              ### ---"
    echo -e "--- ### THE SAME IDEALLY GOES FOR PHPMYADMIN AS WELL !!!                                                                 ### ---"
    echo -e "--- ### ---------------------------------------------------------------------------------------------------------------- ### ---"
else
    echo -e "You have already provisioned this Vagrant machine!"
    echo -e "Run 'vagrant halt && vagrant destroy && vagrant up --provision'"
    echo -e "from your host machine to recreate and re-provision your machine."
fi 
