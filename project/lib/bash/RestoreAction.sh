#!/bin/bash
################################################################################
# Restore Session - LDAP/Mailbox/DistList/Alias
################################################################################

################################################################################
# restore_main_mailbox: Manage the restore action for one or all mailbox
# Options:
#    $1 - The session to be restored
#    $2 - The list of accounts to be restored.
#    $3 - The destination of the restored account
################################################################################
function restore_main_mailbox()
{
  if [[ $SESSION_TYPE == 'TXT' ]]; then
    SESSION=$(egrep ": $1 started" $WORKDIR/sessions.txt | egrep 'started' | \
                  awk '{print $2}' | sort | uniq)
  elif [[ $SESSION_TYPE == "SQLITE3" ]]; then
    SESSION=$(sqlite3 $WORKDIR/sessions.sqlite3 "select * from backup_session where sessionID='$1'")
  fi
  if ! [ -z "$SESSION" ]; then
    logger -i -p local7.info "Restore mail process with session $1 started at $(date)"
    if [[ ! -z $3 && $2 == *"@"* ]]; then
      ERR=$((curl --insecure  "https://$MAILHOST:7071/home/$3/?fmt=tgz"\
         --user "$ADMINUSER":"$ADMINPASS" --upload-file $WORKDIR/$1/$2.tgz) 2>&1)
      if [[ $? -eq 0 ]]; then
        logger -i -p local7.info "Account $2 restored with success"
      else
        logger -i -p local7.err "Error during the restore process for account $2. Error message below:"
        logger -i -p local7.err "$2: $ERR"
      fi
    else
      build_listRST $1 $2
      cat $TEMPACCOUNT | parallel --jobs $MAX_PARALLEL_PROCESS \
               "mailbox_restore $1 {}"
    fi
    logger -i -p local7.info "Restore mail process with session $1 completed at $(date)"
  else
    echo "Nothing to do. Closing..."
    rm -rf $PID
  fi
}

################################################################################
# restore_main_ldap: Manage the restore action for one or all ldap accounts
# Options:
#    $1 - The session to be restored
#    $2 - The list of accounts to be restored.
################################################################################
function restore_main_ldap()
{
  if [[ $SESSION_TYPE == 'TXT' ]]; then
    SESSION=$(egrep ": $1 started" $WORKDIR/sessions.txt | egrep 'started' | \
                  awk '{print $2}' | sort | uniq)
  elif [[ $SESSION_TYPE == "SQLITE3" ]]; then
    SESSION=$(sqlite3 $WORKDIR/sessions.sqlite3 "select * from backup_session where sessionID='$1'")
  fi
  if ! [ -s "$SESSION" ]; then
    echo "Restore LDAP process with session $1 started at $(date)"
    build_listRST $1 $2
    cat $TEMPACCOUNT | parallel --jobs $MAX_PARALLEL_PROCESS \
                              "ldap_restore $1 {}"
    echo "Restore LDAP process with session $1 completed at $(date)"
  else
    echo "Nothing to do. Closing..."
  fi
}
