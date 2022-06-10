#!/usr/bin/env bash

# git remote add ansible ssh://git@git.it-economics.de:7999/in/ansible.git

git commit -a

git pull --quiet --ff-only

git fetch --all
git subtree pull --prefix ansible ansible master --squash

git push
git subtree push --prefix ansible ansible master --squash
