#!/bin/bash

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e
log_info() {
  printf "\n\e[0;35m $1\e[0m\n\n"
}

RAM=`echo $(($(getconf _PHYS_PAGES) * $(getconf PAGE_SIZE) / (1024 * 1024)))`

NGINX=`nginx --version`
MYSQL=`mysql --version`
NODE=`node --version`
PYTHON=`python --version`
PYTHON3=`python3 --version`
PHP=`php --version`
REDIS=`redis-server --version`
VARNISH=`varnish --version`

log_info "Checking your system ..."

if [[ $RAM <= 1999 ]]; then
    echo "You have $RAM available"
    echo "For the installation, you need at least 2GB Memory - https://www.cloudpanel.io/docs/v2/requirements/#memory"
    exit
fi

if [[ $NGINX ]]; then
    echo "You have $NGINX installed"
    echo "For the installation, you need an empty server with Ubuntu 22.04 or Debian 11 with root access - https://www.cloudpanel.io/docs/v2/technology-stack/"
    exit
fi

if [[ $MYSQL ]]; then
    echo "You have $MYSQL installed"
    echo "For the installation, you need an empty server with Ubuntu 22.04 or Debian 11 with root access - https://www.cloudpanel.io/docs/v2/technology-stack/"
    exit
fi

if [[ $NODE ]]; then
    echo "You have $NODE installed"
    echo "For the installation, you need an empty server with Ubuntu 22.04 or Debian 11 with root access - https://www.cloudpanel.io/docs/v2/technology-stack/"
    exit
fi

if [[ $PYTHON ]]; then
    echo "You have $PYTHON installed"
    echo "For the installation, you need an empty server with Ubuntu 22.04 or Debian 11 with root access - https://www.cloudpanel.io/docs/v2/technology-stack/"
    exit
fi

if [[ $PYTHON3 ]]; then
    echo "You have $PYTHON3 installed"
    echo "For the installation, you need an empty server with Ubuntu 22.04 or Debian 11 with root access - https://www.cloudpanel.io/docs/v2/technology-stack/"
    exit
fi

if [[ $PHP ]]; then
    echo "You have $PHP installed"
    echo "For the installation, you need an empty server with Ubuntu 22.04 or Debian 11 with root access - https://www.cloudpanel.io/docs/v2/technology-stack/"
    exit
fi

if [[ $REDIS ]]; then
    echo "You have $REDIS installed"
    echo "For the installation, you need an empty server with Ubuntu 22.04 or Debian 11 with root access - https://www.cloudpanel.io/docs/v2/technology-stack/"
    exit
fi

if [[ $VARNISH ]]; then
    echo "You have $VARNISH installed"
    echo "For the installation, you need an empty server with Ubuntu 22.04 or Debian 11 with root access - https://www.cloudpanel.io/docs/v2/technology-stack/"
    exit
fi

log_info "Install CloudPanel ..."
sudo apt update && apt -y install curl wget sudo

IP=`ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/'`
DISTRO=`cat /etc/*-release | grep "^ID=" | grep -E -o "[a-z]\w+"`
VERSION=`lsb_release --release | cut -f2 | cut -c 1`

echo "Your operating system is $DISTRO"

if [ "$DISTRO" = "debian" ]; then
    if [ "$VERSION" = "11" ]; then    
    
      echo "What version of database engine you want to use? (options: 8.0, 5.7, 10.9, 10.8, 10.7) "
      read MYSQL_VERSION
      echo "Installing preferred Database Engine ... "
      
      if [ "$MYSQL_VERSION" = "8.0" ]; then 
      
          curl -sS https://installer.cloudpanel.io/ce/v2/install.sh -o install.sh; \
          echo "d67e37c0fb0f3dd7f642f2c21e621e1532cadefb428bb0e3af56467d9690b713  install.sh" | \
          sha256sum -c && sudo bash install.sh    
          
      elif [ "$MYSQL_VERSION" = "5.7" ]; then
      
          curl -sS https://installer.cloudpanel.io/ce/v2/install.sh -o install.sh; \
          echo "d67e37c0fb0f3dd7f642f2c21e621e1532cadefb428bb0e3af56467d9690b713  install.sh" | \
          sha256sum -c && sudo DB_ENGINE=MYSQL_5.7 bash install.sh
          
      elif [ "$MYSQL_VERSION" = "10.9" ]; then
      
          curl -sS https://installer.cloudpanel.io/ce/v2/install.sh -o install.sh; \
          echo "d67e37c0fb0f3dd7f642f2c21e621e1532cadefb428bb0e3af56467d9690b713  install.sh" | \
          sha256sum -c && sudo DB_ENGINE=MARIADB_10.9 bash install.sh
          
      elif [ "$MYSQL_VERSION" = "10.8" ]; then
      
          curl -sS https://installer.cloudpanel.io/ce/v2/install.sh -o install.sh; \
          echo "d67e37c0fb0f3dd7f642f2c21e621e1532cadefb428bb0e3af56467d9690b713  install.sh" | \
          sha256sum -c && sudo DB_ENGINE=MARIADB_10.8 bash install.sh
          
      elif [ "$MYSQL_VERSION" = "10.7" ]; then
      
          curl -sS https://installer.cloudpanel.io/ce/v2/install.sh -o install.sh; \
          echo "d67e37c0fb0f3dd7f642f2c21e621e1532cadefb428bb0e3af56467d9690b713  install.sh" | \
          sha256sum -c && sudo DB_ENGINE=MARIADB_10.7 bash install.sh
          
      else
       echo "$MYSQL_VERSION"
       echo "Sorry there is nothing for MySQL/MariaDB v$MYSQL_VERSION"
       exit
      fi
      
      echo "You can now access CloudPanel via Browser: http://$IP:8443"      
  
    else
       echo "Sorry $DISTRO v$VERSION is not supported."
       exit
    fi
    
elif [ "$DISTRO" = "ubuntu" ]; then
    if [ "$VERSION" = "22" ]; then    
    
      echo "What version of database engine you want to use? (options: 8.0, 10.9, 10.8, 10.6) "
      read MYSQL_VERSION
      echo "Installing preferred Database Engine ... "
      
      if [ "$MYSQL_VERSION" = "8.0" ]; then 
      
          curl -sS https://installer.cloudpanel.io/ce/v2/install.sh -o install.sh; \
          echo "d67e37c0fb0f3dd7f642f2c21e621e1532cadefb428bb0e3af56467d9690b713  install.sh" | \
          sha256sum -c && sudo bash install.sh         

          
      elif [ "$MYSQL_VERSION" = "10.9" ]; then
      
          curl -sS https://installer.cloudpanel.io/ce/v2/install.sh -o install.sh; \
          echo "d67e37c0fb0f3dd7f642f2c21e621e1532cadefb428bb0e3af56467d9690b713  install.sh" | \
          sha256sum -c && sudo DB_ENGINE=MARIADB_10.9 bash install.sh
          
      elif [ "$MYSQL_VERSION" = "10.8" ]; then
      
          curl -sS https://installer.cloudpanel.io/ce/v2/install.sh -o install.sh; \
          echo "d67e37c0fb0f3dd7f642f2c21e621e1532cadefb428bb0e3af56467d9690b713  install.sh" | \
          sha256sum -c && sudo DB_ENGINE=MARIADB_10.8 bash install.sh
          
      elif [ "$MYSQL_VERSION" = "10.6" ]; then
      
          curl -sS https://installer.cloudpanel.io/ce/v2/install.sh -o install.sh; \
          echo "d67e37c0fb0f3dd7f642f2c21e621e1532cadefb428bb0e3af56467d9690b713  install.sh" | \
          sha256sum -c && sudo DB_ENGINE=MARIADB_10.6 bash install.sh
          
      else
       echo "$MYSQL_VERSION"
       echo "Sorry there is nothing for MySQL/MariaDB v$MYSQL_VERSION"
       exit
      fi
      
      echo "You can now access CloudPanel via Browser: http://$IP:8443"      
  
    else
       echo "Sorry $DISTRO v$VERSION is not supported."
       exit
    fi
else
   echo "$DISTRO v$VERSION"
   echo "Sorry this is not for you - https://www.cloudpanel.io/docs/v2/requirements/"
   exit
fi
