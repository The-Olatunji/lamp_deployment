# LAMP Stack deployment of Laravel App

# Deployment of Laravel Application Using LAMP Stack

This document outlines the deployment process of a Laravel application using a LAMP (Linux, Apache, MySQL, PHP) stack.

## Bash Script Details

The provided bash script (`lamp_test.sh`) automates the deployment process. Here's an overview of its functionality:

- Updates the Ubuntu server and installs the LAMP stack.
- Configures PHP, MySQL, and Apache settings.
- Clones a Laravel application from GitHub and sets up necessary permissions.
- Installs Composer and Laravel dependencies.
- Configures Apache Virtual Host to serve the Laravel application.
- Restarts web services and enables them to start at boot.

## Ansible Playbook Details

The Ansible playbook orchestrates the execution of the bash script on the target server. Here's what it does:

- Creates the destination directory and copies the bash script to the target server.
- Executes the bash script to deploy the Laravel application.
- Sets up a cron job for uptime monitoring.

## Usage

1. Ensure Ansible is installed on your control node.
2. Update the playbook with the correct host information.
3. Run the playbook using `ansible-playbook playbook.yml`.

## Additional Notes

- Adjust the bash script and playbook as needed for your specific deployment requirements as it's reusable.
- Test the deployment process in a staging environment before applying it to production.

## Addition resources!
![Laravel url](laravel-screenshot.png)
![ansible playbook url](ansible_screenshot.png)
