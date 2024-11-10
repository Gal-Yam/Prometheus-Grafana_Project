#!/bin/bash

if [ -z "$1" ]; then #make sure you wrote a commit msg
  echo "You have to provide a commit message!"
  exit 1
fi

git add .
git commit -m "$1"
git push

echo "yay"
