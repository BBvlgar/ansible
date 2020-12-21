import base64
import os
import subprocess
from subprocess import PIPE

from ansible.plugins.vars import BaseVarsPlugin
import yaml

def _base64_decode_symmetric_key():
    with open(os.environ['GITCRYPT_KEY_PATH'], "rb+") as file:
        byte_key = base64.b64decode(file.read())
        file.seek(0)
        file.write(byte_key)
        file.truncate()

def _unlock_git_crypt():
    try:
        # 1st attempt to read
        with open('environments/production/group_vars/all/03_credentials.yml') as file:
            yaml.load(file, Loader=yaml.FullLoader)
    except UnicodeDecodeError:
        # reading failed, consider encrypted, try unlock
        try:
            _base64_decode_symmetric_key()
            subprocess.run(["git-crypt unlock $GITCRYPT_KEY_PATH"],
                           shell=True, check=True, universal_newlines=True, stdin=PIPE, stdout=PIPE)
        except subprocess.CalledProcessError:
            print("Failed to execute git-crypt unlock")
        try:
            # 2nd attempt to read
            with open('environments/production/group_vars/all/03_credentials.yml') as file:
                yaml.load(file, Loader=yaml.FullLoader)
        except UnicodeDecodeError:
            print("Unable to unlock this repo")

class VarsModule(BaseVarsPlugin):

    REQUIRES_WHITELIST = False

    def get_vars(self, loader, path, entities):
        _unlock_git_crypt()
        return {}

