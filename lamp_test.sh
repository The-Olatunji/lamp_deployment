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
install_lamp=$(sudo apt install apache2 mysql-server php php-curl php-dev libapache2-mod-php php-mysql -y 2>> "$HOME/update_error.log")
echo "$install_lamp"
# check if lamp has installed succesfully
if [[ $? -ne 0 ]]
then
	echo "Some packages were not succesfullu installed, check $error_log for more details"
else	
	echo "LAMP installation was sucessful"
fi

# installing php separately because the needed version is php8.2 and dependencies
get_php_repo="$(sudo add-apt-repository ppa:ondrej/php -yy)"
install_php="$(sudo apt install php8.2 php8.2-mysql php8.2-xml php8.2-mbstring -yy 2>> $error_log)" 
echo "$get_php_repo"
echo "$install_php"

# checking if php8.2 was successfully installed
if [[ $? -ne 0 ]]
then
	echo "Some php packages were not successfully installed check $error_log for details"
else 
	echo "Successfully installed php8.2 and it dependencies"
fi 

# Creating my database using mysql, walk with me...
database_name="laravel_db"
username="tophe"
password="vagrant"
sudo mysql -u root -p
sudo mysql -u root -p -e "CREATE DATABASE $database_name;"
sudo mysql -u root -p -e "CREATE USER $username@'localhost' IDENTIFIED BY '$password';"
sudo mysql -u root -p -e "GRANT ALL PRIVILEGES ON $database_name.* TO $username@'localhost';"
sudo mysql -u root -p -e "FLUSH PRIVILEGES;"
sudo mysql -u root -p -e "EXIT;"

#cloning the laravel repo from github
repo_path=/var/www/html/laravel
get_app_repo="$(sudo git clone https://github.com/laravel/laravel.git $repo_path 2>> $error_log)"
echo "$get_app_repo"
# check if cloning was succesful
if [[ $? -ne 0]]
then
	echo "Ooops, Git cloning unsuccessful, check $error_log"
else 
	echo "Successfully cloned Laravel application"
fi 

# Install composer
get_composer="$(sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');")"
install_composer="$(sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer -y)"
echo "$get_composer"
echo "$install_composer"
if [[ $? -ne 0]]
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

# Inputing mysql parameters into .env file 
# Database parameters
DB_CONNECTION="mysql"
DB_HOST="localhost"
DB_PORT="3360"
DB_DATABASE="$database_name"
DB_USERNAME="$username"
DB_PASSWORD="$password"

# Path to Laravel .env file
ENV_FILE="/var/www/html/laravel/.env"

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
sudo composer install -yy
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


