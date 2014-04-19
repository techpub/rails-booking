#!/bin/sh
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_DIR="$(echo $CURRENT_PATH | sed -e "s/tools//g")tmp/backups"
DUMPFILE=tsa_production.sql
USER=rupert
PASSWORD=ENV['DBPASSWORD']

download(){
  rm -Rf $BACKUP_DIR/$DUMPFILE*
  scp rupert@robin:/home/rupert/backup/db/$DUMPFILE.gz $BACKUP_DIR/
  gzip -d $BACKUP_DIR/$DUMPFILE.gz
}

drop_create_import(){
  echo "Dropping..."
  mysqladmin -f -u$USER -p$PASSWORD drop $1

  echo "Creating..."
  mysqladmin -f -u$USER -p$PASSWORD create $1

  echo "Importing $BACKUP_DIR/$DUMPFILE to $1..."
  mysql -u$USER -p$PASSWORD $1 < $BACKUP_DIR/$DUMPFILE
}

ask(){
  echo "Do you want to install in $1? Continue(y/n)?"
  read answer
  if [ $answer = 'y' ]; then
    drop_create_import $1
    echo "Done."
  fi
}

ask_import_all(){
  echo "Do you want to install to all environments? Continue(y/n)?"
  read answer
  if [ $answer = 'y' ]; then
    drop_create_import tsa_production
    drop_create_import tsa_development
    drop_create_import tsa_test
  else
    ask tsa_production
    ask tsa_development
    ask tsa_test
  fi
}


echo "Where will I pull the production database?"
echo "1. Download from remote "
echo "2. Dump production from localhost"
echo "3. Use existing $BACKUP_DIR/$DUMPFILE"; read ans

if [ $ans -eq "1" ];then
  echo "Downloading..."
  download
elif [ $ans -eq "2" ]; then
  mysqldump -u$USER -p$PASSWORD tsa_production > $BACKUP_DIR/$DUMPFILE
else
  echo "No option chosen."
fi

ask_import_all

echo "Done."




