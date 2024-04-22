#!/bin/bash

error_log="$HOME/update_error.log"
logfile="$HOME/update.log"

#update Ubuntu server
echo "Updating..."
sudo apt update -y 1>> $logfile 2>> $error_log
if [[ $? -ne 0 ]]
then
	echo "An error occured, please check $error_log file"
else
	echo "Ubuntu packages updated successfully"
fi

# installing LAMP and it dependecies
echo "Installing LAMP STACK..."
echo "Hold your breathe..."
sleep 2
install_lamp=$(sudo apt install apache2 mysql-server -y 2>> "$HOME/update_error.log")
echo "$install_lamp"
# check if lamp has installed succesfully
if [[ $? -ne 0 ]]
then
	echo "Some packages were not succesfullu installed, check $error_log for more details"
else	
	echo "LAMP installation was sucessful"
fi

# installing php separately because the needed version is php8.2 and dependencies
get_php_repo="$(sudo add-apt-repository ppa:ondrej/php -y)"
echo "$get_php_repo"
#update packages after getting php repo
sudo apt update
sudo apt install php8.2 -y
sudo apt install php8.2-curl php8.2-mysql php8.2-xml php8.2-mbstring php8.2-pdo -yy
php -v

# Creating my database using mysql, walk with me...
database_name="laravel_db_"
username="tophee"
password="vagrant"
sudo mysql -u root -e "CREATE DATABASE $database_name;"
sudo mysql -u root -e "CREATE USER $username@'localhost' IDENTIFIED BY '$password';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON $database_name.* TO $username@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"
sudo mysql -u root -e "EXIT;"

#cloning the laravel repo from github
repo_path=/var/www/laravel
get_app_repo="$(sudo git clone https://github.com/laravel/laravel.git $repo_path 2>> $error_log)"
echo "$get_app_repo"
# check if cloning was succesful
if [[ $? -ne 0 ]]
then
	echo "Ooops, Git cloning unsuccessful, check $error_log"
else 
	echo "Successfully cloned Laravel application"
fi 
cd $repo_path
sudo chmod -R 775 storage
sudo chmod -R 775 bootstrap/cache
sudo chown -R www-data:www-data storage
sudo chown -R www-data:www-data bootstrap

echo "Permission changed!!!"
# Install composer
cd $repo_path
get_composer="$(sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');")"
install_composer="$(sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer -y)"
echo "$get_composer"
echo "Installing composer..."
echo "$install_composer"

if [[ $? -ne 0 ]]
then
        echo "Ooops, Composer installation unsuccessful"
else
        echo "Successfully installed Composer, now unlinking composer-setup.php..."
fi
unlink_compser_setup="$(sudo php -r "unlink('composer-setup.php');")"
echo "$unlink_composer_setup"

#copy .env_example to .env
echo "Copying $repo_path/.env.example into $repo_path/.env"
copy_env="$(sudo cp $repo_path/.env.example $repo_path/.env)"
echo "$copy_env"
sudo chmod 644 $repo_path/.env

# Inputing mysql parameters into .env file 
# Database parameters
DB_CONNECTION="mysql"
DB_HOST="localhost"
DB_PORT="3306"
DB_DATABASE="$database_name"
DB_USERNAME="$username"
DB_PASSWORD="$password"

# Path to Laravel .env file
ENV_FILE="$repo_path/.env"

# Check if the .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found in the Laravel directory"
    exit 1
fi

# Backup existing .env file
sudo cp "$ENV_FILE" "$ENV_FILE.bak"

# Uncomment and update existing database parameters in .env file
sudo sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=$DB_CONNECTION/" "$ENV_FILE"
sudo sed -i "s/^# *DB_HOST=.*/DB_HOST=$DB_HOST/" "$ENV_FILE"
sudo sed -i "s/^# *DB_PORT=.*/DB_PORT=$DB_PORT/" "$ENV_FILE"
sudo sed -i "s/^# *DB_DATABASE=.*/DB_DATABASE=$DB_DATABASE/" "$ENV_FILE"
sudo sed -i "s/^# *DB_USERNAME=.*/DB_USERNAME=$DB_USERNAME/" "$ENV_FILE"
sudo sed -i "s/^# *DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" "$ENV_FILE"

echo "Database parameters updated in .env file successfully"

# Install php dependencies using Composer
cd $repo_path
# sudo chown -R $USER:$USER $repo_path
sudo composer install --no-interaction --optimize-autoloader --no-dev

#Generate the application key
sudo php artisan key:generate
if [[ $? -ne 0 ]]
then
	echo "php artisan key:gen NOT successful"
else
	echo "php artisan key:gen successful"
fi
#Migrate 
sudo php artisan migrate
if [[ $? -ne 0 ]]
then
	echo "php artisan migration FAILED!!!"
else
	echo "php artisan migration SUCCESSFUL"
fi
#Config laravel.conf file 
CONF_PATH="/etc/apache2/sites-available"
sudo chmod o+w $CONF_PATH
LARAVEL_CONF="$CONF_PATH/laravel.conf"
sudo cat > "$LARAVEL_CONF" <<EOF
<VirtualHost *:80>
   #ServerName localhost
    ServerAlias 192.168.33.20 192.168.33.13

    DocumentRoot $repo_path/public
    <Directory $repo_path/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/apache2/laravel_error.log
    CustomLog /var/log/apache2/laravel_access.log combined
</VirtualHost>
EOF

echo "laravel.conf file successfully created"
echo "enabling site..."
sleep 2
sudo chown www-data:www-data $LARAVEL_CONF
#Enable the site and disable default apache page
sudo a2ensite laravel.conf
sudo a2dissite 000-default.conf
#Starting services
echo "Starting web services"
sleep 2
start_apache2="$(sudo systemctl restart apache2)"
start_mysql="$(sudo systemctl restart apache2)"

echo "$start_apache2"
echo "$start_mysql"
echo "****************************"
#enabling the services
echo "****************************"

#enabling the services
echo "Enabling services"
sleep 2
enable_apache2="$(sudo systemctl enable apache2)"
enable_mysql="$(sudo systemctl enable mysql)"
echo "$enable_apache2"
echo "$enable_mysql"

echo "BASH SCRIPT RUN COMPLETED"
exit
