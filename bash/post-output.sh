#!/bin/bash

filesToExec=`ls -f ../data/output/*.xml`
auth='Basic '$1

for file in $filesToExec
do
  echo $file
  curl -k --url "https://oldcat.unact.ru/iexp/xmlb" --header "Authorization: $auth" --data @$file
  echo
done
