import base64
import os, glob, subprocess
import tempfile
from subprocess import PIPE, DEVNULL

from ansible.plugins.vars import BaseVarsPlugin

###
## analyze the current Ansible folders for git-crypt
###
def checkGitCrypt():

    cwd = os.getcwd()
    gits = []

    # change working directory to git base
    while not os.path.exists( '.git' ):
        os.chdir('..')
        if os.getcwd() == '/':
            os.chdir( cwd )
            print( 'You seem not to use this Ansible within Git structures ...' )
            gits.append( '.' )
            break

    # fetch all Git repos of this project
    gitDirs = glob.glob( "**/.git", recursive=True )
    for d in gitDirs:
        d = d.split('/')
        i = 0
        x = os.getcwd()
        ok = True
        while i < len(d):
            x += '/' + d[i]
            if os.path.islink( x ):
                ok = False
                break
            i += 1
        if ok:
            d.pop()
            if not d:
                d = [ '.' ]
            gits.append( '/'.join(d) )

    # check all git repos for files to unlock
    wd = os.getcwd()
    for git in gits:
        os.chdir( wd )
        os.chdir( git )
        if not checkUnlockedState():
            unlockGitCrypt()

    os.chdir( cwd )
    if keyFileObj is not None:
        keyFileObj.close()

###
## function to check if the current repo is unlocked (return True) or not (return False)
###
def checkUnlockedState():
    try:
        # command from git-crypt GitHub Repo / Issues
        # https://github.com/AGWA/git-crypt/issues/69#issuecomment-690161853
        subprocess.run( ['git ls-tree -r --name-only -z HEAD | xargs -0 grep -qsa "\\x00GITCRYPT"' ], shell=True, check=True, text=True, stdout=DEVNULL )
        return False
    except subprocess.CalledProcessError as e:
        # the command above exists with return code 1 if git-crypt unlocked
        return True

###
## function that acutally performs the unlocking
###
def unlockGitCrypt():
    gcp = whichGitCrypt()
    success = False
    # try to unlock git-crypt with GPG keys available
    try:
        subprocess.run( [ gcp, 'unlock' ], check=True, text=True, stdout=PIPE )
        print( 'unlocked by using available GPG keys' )
        success = True
    except subprocess.CalledProcessError:
        print( 'GPG Key not available – trying to use symmetric key' )
        try:
            _base64_decode_symmetric_key()
            subprocess.run( [ gcp, 'unlock', gitcryptKeyPath ], check=True, text=True, stdout=PIPE )
            print( 'Unlocking with symmetric key successfull' )
            success = True
        except subprocess.CalledProcessError as e:
            print( 'Unlocking git-crypt by symmetric key failed:' )
            print()
            print( e )
    if success:
        if not checkUnlockedState():
            print( 'Unable to unlock this repo: ' + os.getcwd() )

###
## retrieve the installation path of git-crypt
##
## there is also the possibility to override the system git-crypt path
## by using GIT_CRYPT_PATH Env variable
###
gitCryptPath = ''
def whichGitCrypt():
    global gitCryptPath
    if gitCryptPath == '':
        try:
            gcp = os.environ['GIT_CRYPT_PATH']
            gitCryptPath = gcp
        except:

            result = subprocess.run( [ 'which', 'git-crypt' ], check=True, text=True, stdout=PIPE )
            gitCryptPath = result.stdout.strip()
    return gitCryptPath

###
## function that retrieves the symmetric key for git-crypt
###
gitcryptKeyPath = ''
keyFileObj = None
def _base64_decode_symmetric_key():
    global gitcryptKeyPath
    global keyFileObj
    if gitcryptKeyPath == '':
        keyFileObj = tempfile.NamedTemporaryFile()
        gitcryptKeyPath = keyFileObj.name
        with open(os.environ['GITCRYPT_KEY_PATH'], "r") as b64:
            byte_key = base64.b64decode(b64.read())
            keyFileObj.seek(0)
            keyFileObj.write(byte_key)
            keyFileObj.truncate()

###
## necessary for being a var plugin
###
class VarsModule(BaseVarsPlugin):

    REQUIRES_WHITELIST = False

    def get_vars(self, loader, path, entities):
        checkGitCrypt()
        return {}

