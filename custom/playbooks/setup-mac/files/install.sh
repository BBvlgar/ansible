#!/bin/bash
xcode-select --install
sudo xcodebuild -license accept
if ! command -v brew &> /dev/null; then
    echo "brew could not be found and will be installed now"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if ! command -v ansible &> /dev/null; then
    echo "ansible could not be found and will be installed now"
    brew update
    brew install ansible
fi

cd ../
ansible-galaxy install -r requirements.yml  -p ./roles
ansible-playbook -K main.yml
