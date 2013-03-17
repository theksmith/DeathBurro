#!/bin/sh
DIR=$(cd $(dirname "$0") && pwd)
echo `/mnt/storage/usr/java/ejre1.6.0_25/bin/java -Xrs -jar $DIR/deathburro_mail.jar $@`
# this was an attempt to wrap the java execute call, this turned out not to work with Flash so oh well