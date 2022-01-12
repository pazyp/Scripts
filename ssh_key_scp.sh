#!/bin/sh
# Andrew Pazikas
#

KEY="$HOME/.ssh/id_rsa.pub"

if [ ! -f ~/.ssh/id_rsa.pub ];then
    echo "Private key not found at $KEY"
    while true; do
        read -p "Do you wish to generate a private key?" yn
        case $yn in
             [Yy]* ) ssh-keygen -t rsa; break;;
             [Nn]* ) exit;;
             * ) echo "Please answer yes or no!";;
     esac
done
exit

fi

if [ -z $1 ];then
    echo "Please specify user@host as the first parameter of this script"
    exit
fi

echo "Putting your key on $1... "

KEYCODE=`cat $KEY`
ssh -q $1 "mkdir ~/.ssh 2>/dev/null; chmod 700 ~/.ssh; echo "$KEYCODE" >> ~/.ssh/authorized_keys; chmod 644 ~/.ssh/authorized_keys"

echo "done :D Key Uploaded!"
