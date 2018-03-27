#!/bin/bash
################################################################################

################################################################################
# check_env: Check the environment if everything is okay to begin the install
################################################################################
function check_env() {
  printf "  Root Privileges...	          "
  if [ $(id -u) -ne 0 ]; then
    printf "[NO ROOT]\n"
  	echo "You need root privileges to install zmbackup"
  	exit $ERR_NOROOT
  else
    printf "[ROOT]\n"
  fi
  printf "  Old Zmbackup Install...	  "
  VERSION=$((su - $OSE_USER -c "zmbackup -v") 2> /dev/null)
  if [ $? != 0 ]; then
    printf "[NEW INSTALL]\n"
    UPGRADE="N"
  elif [[ $1 == '--remove' ]] || [[ $1 == '-r' ]]; then
    printf "[UNINSTALL] - EXECUTING UNINSTALL ROUTINE\n"
    UPGRADE="N"
  elif [[ $1 == '--force-upgrade' ]] || [[ $VERSION != $ZMBKP_VERSION ]]; then
    printf "[OLD VERSION] - EXECUTING UPGRADE ROUTINE\n"
    UPGRADE="Y"
  else
    echo "[NEWEST VERSION] - Nothing to do..."
    exit 0
  fi
  printf "  Checking OS...	          "
  which apt > /dev/null 2>&1
  if [ $? = 0 ]; then
    printf "[UBUNTU SERVER]\n"
    SO="ubuntu"
  fi
  which yum > /dev/null 2>&1
  if [[ $? = 0 ]]; then
    printf "[RED HAT ENTERPRISE LINUX]\n"
    SO="redhat"
  elif [[ -z $SO ]]; then
    printf "[UNSUPPORTED]\n"
    exit 1
  fi
}

################################################################################
# check_config: Check the environment for other configurations
################################################################################
function check_config() {
  echo "Recovering all the configuration... Please wait"
  OSE_INSTALL_HOSTNAME=`su - $OSE_USER -c "zmprov gad | head -1"`
  OSE_INSTALL_ADDRESS=`grep -m 1 $OSE_INSTALL_HOSTNAME /etc/hosts|awk '{print $1}'`
  OSE_INSTALL_LDAPPASS=`su - $OSE_USER -c "zmlocalconfig -s zimbra_ldap_password"|awk '{print $3}'`

  echo ""
  echo "Here is a Summary of your settings:"
  echo ""
  echo "Zimbra User: $OSE_USER"
  echo "Zimbra Hostname: $OSE_INSTALL_HOSTNAME"
  echo "Zimbra IP Address: $OSE_INSTALL_ADDRESS"
  echo "Zimbra LDAP Password: $OSE_INSTALL_LDAPPASS"
  echo "Zimbra Zmbackup Account: $ZMBKP_ACCOUNT"
  echo "Zimbra Zmbackup Password: $ZMBKP_PASSWORD"
  echo "Zimbra Install Directory: $OSE_INSTALL_DIR"
  echo "Zimbra Backup Directory: $OSE_DEFAULT_BKP_DIR"
  echo "Zmbackup Install Directory: $ZMBKP_SRC"
  echo "Zmbackup Settings Directory: $ZMBKP_CONF"
  echo "Zmbackup Backups Days Max: $ROTATE_TIME"
  echo "Zmbackup Number of Threads: $MAX_PARALLEL_PROCESS"
  echo "Zmbackup Backup Lock: $LOCK_BACKUP"
  echo "Zmbackup Session Default Type: $SESSION_TYPE"
  echo ""
  echo "Press ENTER to continue or CTRL+C to cancel."
  read
}
