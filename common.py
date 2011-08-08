from subprocess import PIPE, Popen, STDOUT
import subprocess
from signal import alarm, signal, SIGALRM, SIGKILL
import os, sys, traceback
from os.path import *
import threading, time

def printd(msg, distro=None):
    if distro:
        msg = "%s: %s"%(distro, msg)
    sys.stderr.write(msg)
    sys.stderr.flush()

class TimeOutException(Exception):
    pass

class BashFailureException(Exception):
    pass

class bash:
    def __init__(self, args, usePipe=False, timeout=-1):
        self.args = ' '.join(args)
        self.timeout = timeout
        self.process = None
        self.usePipe = usePipe
        printd("%s\n"%self.args)
        self.run()

    def run(self):
        class Alarm(Exception):
            pass
        def alarm_handler(signum, frame):
            raise Alarm

        if self.usePipe:
            self.process = Popen(self.args, shell=True, stdout=PIPE, stderr=PIPE)
        else:
            self.process = Popen(self.args, shell=True)
            
        if self.timeout != -1:
            signal(SIGALRM, alarm_handler)
            alarm(self.timeout)

        try:
            self.stdout, self.stderr = self.process.communicate()
            if self.timeout != -1:
                alarm(0)
        except Alarm:
            os.kill(self.process.pid, SIGKILL)
            raise  TimeOutException("Timeout during command execution")

        if self.process.returncode != 0: 
            raise  BashFailureException("%s failed"%self.args)

def useWaf():
    return True
    
def scriptPath(script):
    return join(dirname(sys.argv[0]), script)

def FormatErrMsg(e):
    if not isinstance(e, Exception):
        return ''
    
    tb = sys.exc_info()[2]
    return "%s\n%s"%(str(e), ' '.join(traceback.format_tb(tb)))

ENV_CFG_FILE="env.cfg"
ENV_CFG_FILE_ON_HUDSON=join('/tmp', ENV_CFG_FILE)
BUILD_DIR='/root/cloudstack/build'
REMOTE_USER='root'
DEPS_DIR='/root/deps'
YUM_REPO='yumrepo.lab.vmops.com'
APT_REPO='aptrepo.lab.vmops.com'
YUM_RPM_DIR='/var/www/html/repositories'
APT_DEB_DIR='/var/www/html/repositories'
YUM_RELEASE_DIR='/var/www/html/releases'
APT_RELEASE_DIR='/var/www/html/releases'