#!/bin/bash

# The following packages must be installed on the server to run correctly:
#  build-essential
#  curl
#  gunicorn
#  nginx
#  python-is-python3
#  python3-dev
#  python3-pip
#  python3.10-venv
#  unzip
#  certbot classic

this_script=$(readlink -f ${BASH_SOURCE})
script_dir=$(dirname ${this_script})
home_dir=$(readlink -f ${HOME})
config_dir=${home_dir}/sms_config.d
log_dir=${home_dir}/sms_logs
repo_root=$(readlink -f ${script_dir}/..)

# Stop services if they are already running - this may result in errors if the services don't already exist which we'll ignore
echo "Stop services"
sudo service gunicorn stop
sudo service nginx stop

echo "Creating configuration files"
# Ensure necessary directories exist
/usr/bin/mkdir -p "${config_dir}/run"
if [[ $? != 0 ]]; then
    echo "Error creating directory ${config_dir}/run"
    # Failure to create this directory is fatal
    exit
fi
/usr/bin/mkdir -p "${log_dir}/gunicorn"
if [[ $? != 0 ]]; then
    echo "Error creating directory ${log_dir}/gunicorn"
fi
/usr/bin/mkdir -p "${repo_root}/sms_core/media"
if [[ $? != 0 ]]; then
    echo "Error creating directory ${repo_root}/sms_core/media"
fi


# Create the configuration appropriate for this installation
/usr/bin/cp ${script_dir}/sms_core/nginx/nginx.conf ${config_dir}/nginx.conf
if [[ $? != 0 ]]; then
    echo "Error copying ${script_dir}/sms_core/nginx/nginx.conf to ${config_dir}/nginx.conf"
fi

# Set up string replacements
sed_script="s|ROOT_DIR|${repo_root}|g;s|CONFIG_DIR|${config_dir}|g;s|USER|${USER}|g;s|LOG_DIR|${log_dir}|g"

# ccs-boot/ccs_init.py should have set up the virtual environment but reload in
# case we are in a development environment and things have been manually changed

echo "Setup venv"
cd "${repo_root}"
if [[ ! -d venv ]]; then
    if [[ -e venv ]]; then
        echo "Unable to setup venv, local file exists"
        ls -ld ${PWD}/venv
    else
        python -m venv venv
        if [[ $? != 0 ]]; then
            echo "Unable to create virtual environment ${PWD}/venv"
            exit
        fi
    fi
fi

"${repo_root}/venv/bin/python" -m pip install -r "${repo_root}/requirements.txt"
if [[ $? != 0 ]]; then
    echo "Unable to install requirements specified in ${repo_root}/requirements.txt"
    exit
fi

use_ssl=false
nginx_template="$script_dir/sms_core/nginx/sms.conf"

Search for an installed certificate for the constructed domain name
installed_certificates=$(sudo /usr/bin/certbot certificates)
if [[ $? != 0 ]]; then
    echo "Error listing certificates, assuming none installed"
else
    found_cert=false
    while read -r line; do
        case $line in
            *"Domains: "*"moszczynski.co.uk"*)
                # Parsing a certificate that includes our domain
                found_cert=true
                ;;
            *"Domains: "*)
                # Parsing a certificate that does not include our domain
                found_cert=false
                ;;
            *"Certificate Path:"*)
                if [[ $found_cert == "true" ]]; then
                    cert_path=$(/usr/bin/sed -e 's/.*: \([^ ]*\).*/\1/g'<<< "$line")
                fi
                ;;
            *"Private Key Path:"*)
                if [[ $found_cert == "true" ]]; then
                    key_path=$(/usr/bin/sed -e 's/.*: \([^ ]*\).*/\1/g'<<< "$line")
                fi
                ;;
        esac
    done <<< "$installed_certificates"
    if [[ -n "$cert_path" && -n "$key_path" ]]; then
        sed_script="${sed_script};s|FULLY_QUALIFIED_URL|$moszczynski.co.uk|g;s|RM_CERT|${cert_path}|g;s|RM_KEY|${key_path}|g"
        nginx_template="$script_dir/sms_core/nginx/ssl.sms.conf"
    fi
fi


# Create copies of all configuration files needed with directory/user specifications changed as needed
/usr/bin/sed -e "${sed_script}" "${nginx_template}" > "${config_dir}/nginx.sms.conf"
if [[ $? != 0 ]]; then
    echo "Error creating ${config_dir}/nginx.sms.conf"
fi
/usr/bin/sed -e "${sed_script}" $script_dir/sms_core/gunicorn/gunicorn.service > ${config_dir}/gunicorn.service
if [[ $? != 0 ]]; then
    echo "Error creating ${config_dir}/gunicorn.service"
fi
/usr/bin/sed -e "${sed_script}" $script_dir/sms_core/gunicorn/gunicorn.env > ${config_dir}/gunicorn.env
if [[ $? != 0 ]]; then
    echo "Error creating ${config_dir}/gunicorn.env"
fi
/usr/bin/sed -e "${sed_script}" $script_dir/sms_core/gunicorn/gunicorn.conf.py > ${config_dir}/gunicorn.conf.py
if [[ $? != 0 ]]; then
    echo "Error creating ${config_dir}/gunicorn.conf.py"
fi
# If this script has already been run gunicorn.logrotate will be owned by root, take ownership back
sudo /usr/bin/chown ${USER} ${config_dir}/gunicorn.logrotate
if [[ $? != 0 ]]; then
    echo "Error changing ownership of ${config_dir}/gunicorn.logrotate to '${USER}'"
fi
/usr/bin/sed -e "${sed_script}" $script_dir/sms_core/gunicorn/gunicorn.logrotate > ${config_dir}/gunicorn.logrotate
if [[ $? != 0 ]]; then
    echo "Error creating ${config_dir}/gunicorn.logrotate"
fi
/usr/bin/chmod 644 ${config_dir}/gunicorn.logrotate
if [[ $? != 0 ]]; then
    echo "Error changing mode of ${config_dir}/gunicorn.logrotate"
fi

echo "Create symbolic links to configuration files"
sudo /usr/bin/ln -sf ${config_dir}/nginx.conf /etc/nginx
sudo /usr/bin/ln -sf ${config_dir}/nginx.sms.conf /etc/nginx/sites-enabled
sudo /usr/bin/ln -sf ${config_dir}/gunicorn.service /etc/systemd/system
sudo /usr/bin/ln -sf ${config_dir}/gunicorn.logrotate /etc/logrotate.d/gunicorn

echo "Changing ownership of logrotate configuration file"
sudo /usr/bin/chown root ${config_dir}/gunicorn.logrotate
if [[ $? != 0 ]]; then
    echo "Error changing ownership of ${config_dir}/gunicorn.logrotate"
fi

echo "Reload systemd to pick up new .service files"
sudo systemctl daemon-reload

echo "Django managment"
"${repo_root}/venv/bin/python" "${repo_root}/sms_core/manage.py" collectstatic --clear --no-input
"${repo_root}/venv/bin/python" "${repo_root}/sms_core/manage.py" migrate
/usr/bin/echo "{\"git_desc\":\"$(git -C "${repo_root}" describe --all --always)\",\"git_sha\":\"$(git -C "${repo_root}" rev-parse --verify HEAD)\",\"git_sha_short\":\"$(git -C "${repo_root}" rev-parse --verify --short HEAD)\"}" > "${repo_root}/sms_core/media/version.json"

echo "Start services"
sudo service nginx start
sudo service gunicorn start
