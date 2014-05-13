#!/bin/bash
# Create new MySQL database,
# download & install latest stable Drupal7 to $DOCUMENTROOT/www.$PROJECT.$TLD/drupal7
# and link "public" to "drupal7"

# Environment-configurable variables
MYSQLUSER=root
MYSQLPASS=rootPW
DRUPALUSER=user
DRUPALPASS=userPW
HOST=localhost
DBPREFIX=drupal_
DOCUMENTROOT=$HOME/www
LANG=de

if [ $# -lt 2 ]
then
  echo "USAGE: $0 project/domainname tld";
  echo "New MySQL database requires first argument (the name of the project to create a development database for = domain name)."
  echo "New Drupal site requires second argument (the top level domain of the domain)."
  exit
fi

PROJECT="$1"
TLD="$2"

MYSQL=`which mysql`
Q1="CREATE DATABASE IF NOT EXISTS $DBPREFIX$PROJECT;"
Q2="GRANT ALL ON $DBPREFIX$PROJECT.* TO '$DRUPALUSER'@'$HOST' IDENTIFIED BY '$DRUPALPASS';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"

# Execute database creation
$MYSQL -u$MYSQLUSER -p$MYSQLPASS -e "$SQL"

# Check wether database was created
RESULT=$($MYSQL -u$PROJECT -p$PROJECT -e "SHOW DATABASES LIKE '$DBPREFIX$PROJECT';")
if [ -n "$RESULT" ]
then
  echo "A database has been created with the name set to $DBPREFIX$PROJECT."
  echo "User set to $DRUPALUSER and password set to $DRUPALPASS."
else
  echo "Oups – Something went wrong! The database could not be created or the new user has no access."
  exit
fi

DRUSH=`which drush`
if [[ $ZUI != *drush* ]]
then
  echo "drush is required to install Drupal with this script."
  echo "Check out https://github.com/drush-ops/drush for more information."
  exit
fi

SITE="$PROJECT.$TLD"

# Create project directory in $DOCUMENTROOT
echo "Creating $DOCUMENTROOT/www.$SITE"
mkdir "$DOCUMENTROOT/www.$SITE"

# Download latest stable Drupal7
$DRUSH dl drupal-7 --destination="$DOCUMENTROOT/www.$SITE/drupal7"

# Install the site using drush
cd "$DOCUMENTROOT/www.$SITE/drupal7/"
$DRUSH site-install --db-url=mysql://$DRUPALUSER:$DRUPALPASS@$HOST/$DBPREFIX$PROJECT \
--account-name=Administrat0r --account-pass=5f_dX3-toUVL2rPh8WsM \
--account-mail=info@lucadou.net --site-mail=info@$SITE --site-name=$SITE --clean-url=0

# Install & enable custom language
if [[ $LANG != "en" ]]
then
  $DRUSH dl drush_language
  $DRUSH dl l10n_update && drush en -y $_
  $DRUSH language-add $LANG && drush language-enable $_
  $DRUSH l10n-update-refresh
  $DRUSH l10n-update
  $DRUSH language-default $LANG
fi

# Create public symlink to drupal7
cd ..
ln -s drupal7 public
