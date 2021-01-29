#!/bin/bash
xcode-select --install
sudo xcodebuild -license accept
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update
brew install ansible
cd ../
ansible-galaxy install -r requirements.yml
ansible-playbook -K main.yml
