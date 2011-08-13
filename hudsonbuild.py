'''
Created on Jun 24, 2011

@author: frank
'''

from common import *

buildMachines = {
  "rhel5": {"host":"build-rhel5", "isDeb":False, "subDir":"rhel/5"},
  "fedora14": {"host":"build-fc14", "isDeb":False, "subDir":"fedora/14"},
  "fedora13": {"host":"build-fc13", "isDeb":False, "subDir":"fedora/13"},
  "rhel6": {"host":"build-rhel6", "isDeb":False, "subDir":"rhel/6"},
  "ubuntu10.10": {"host":"build-ubuntu1010", "isDeb":True, "subDir":"ubuntu/10.10"},
  "ubuntu10.04" : {"host":"build-ubuntu1004", "isDeb":True, "subDir":"ubuntu/10.04"},
  #"ubuntu11" : {"host":"natty", "isDeb":True,"subDir":"ubuntu/11" },
}

processes = []
environ = {}

def compareVersion(ver1, ver2):
    ver1s = ver1.split('.')
    ver2s = ver2.split('.')
    
    ver1s = [int(i) for i in ver1s]
    ver2s = [int(i) for i in ver2s]
    
    if ver1s[0] < ver2s[0]: return -1
    elif ver1s[0] == ver2s[0]: pass
    else: return 1
    
    if ver1s[1] < ver2s[1]: return -1
    elif ver1s[1] == ver2s[1]: pass
    else: return 1
    
    if ver1s[2] < ver2s[2]: return -1
    elif ver1s[2] == ver2s[2]: return 0
    else: return 1
    
def getInstallScript():
    installScripts = {
        'nobaremetal':'install/rpminstall_nobaremetal.sh',
        'rpmfull':'install/rpminstall_full.sh',
        'debfull':'install/debinstall_full.sh',
        'myclouddeb':'install/mycloud-agent.sh',
    }
    
    def getDebInstallScript():
        if os.environ["BUILD_TARBALL"] == "mycloud-agent":
            return scriptPath(installScripts['myclouddeb'])
        else:
            return scriptPath(installScripts['debfull'])
    
    def getRpmInstallScript():
        if compareVersion(environ['PACKAGE_VERSION'], '2.2.8') < 0:
            return scriptPath(installScripts['nobaremetal'])
        else:
            return scriptPath(installScripts['rpmfull'])
    
    if environ['IS_DEB'] == 'True':
        return getDebInstallScript()
    else:
        return getRpmInstallScript()
    
def prepareEnv(distro):
    def isDeb():
        params = buildMachines[distro]
        return str(params['isDeb'])
    
    environ['BUILDABLE_TARGET'] = os.environ['BUILDABLE_TARGET']
    environ['LABEL_AS_PRERELEASE'] = os.environ['LABEL_AS_PRERELEASE']
    environ['DO_DISTRO_PACKAGES'] = distro
    environ['PUSH_TO_REPO'] = os.environ['PUSH_TO_REPO']
    environ['PACKAGE_VERSION'] = os.environ['PACKAGE_VERSION']
    environ['BUILD_TARBALL'] = os.environ['BUILD_TARBALL']
    environ['BUILD_USER'] = os.environ['BUILD_USER']
    environ['BUILD_NUMBER'] = os.environ['BUILD_NUMBER']
    environ['PUSH_TO_S3'] = os.environ['PUSH_TO_S3']
    environ['GIT_SOURCE_DIR'] = 'source'
    environ['USE_WAF'] = str(useWaf())
    environ['REMOTE_USER']= REMOTE_USER
    environ['RESULT_DIR']='result'
    environ['RPM_RESULT_DIR']='rpms'
    environ['DEB_RESULT_DIR']='debs'
    environ['DEPS_DIR']=DEPS_DIR
    environ['YUMREPO']=YUM_REPO
    environ['YUMREPO_RPM_DIR']=YUM_RPM_DIR
    environ['YUMREPO_RELEASE_DIR']=YUM_RELEASE_DIR
    environ['APTREPO']=APT_REPO
    environ['APTREPO_DEB_DIR']=APT_DEB_DIR
    environ['APTREPO_RELEASE_DIR']=APT_RELEASE_DIR
    environ['IS_DEB'] = isDeb()
    environ['SUB_DIR'] = buildMachines[distro]['subDir']
    
    
    
    fd = open(ENV_CFG_FILE_ON_HUDSON, "w")
    for k in environ:
        item = "=".join([k, environ[k]])
        fd.write(item)
        fd.write('\n')
    fd.close()

def prepareBuildScrpits(host):
    scripts = ['client.py', 'common.py', 'clone.sh', 'builddeb.sh', 'buildrpm.sh', 'buildrpmtarball.sh',
               'postrpms.sh', 'commons.sh', 'postdebs.sh', 'builddebtarball.sh', ENV_CFG_FILE_ON_HUDSON]
    
    remoteHost = '%s@%s'%(REMOTE_USER, host)
    bash(['ssh', remoteHost, '"mkdir -p %s"'%BUILD_DIR])
    for s in scripts:
        bash(['scp', s, '%s:%s'%(remoteHost, BUILD_DIR)])
        
    installscript = getInstallScript()
    bash(['scp', installscript, '%s:%s/install.sh'%(remoteHost, BUILD_DIR)])
    
def startBuildThread(distro, host):
    def run(distro, host):
        global processes
        
        remoteHost = '%s@%s'%(REMOTE_USER, host)
        cmd = 'ssh %s "cd %s && python client.py && cd -"' % (remoteHost, BUILD_DIR)
        printd("Build beginning %s\n"%cmd, distro)
        p = subprocess.Popen(cmd, shell=True, stdout=PIPE, stderr=STDOUT)
        p.cmd = cmd
        p.distro = distro
        processes.append(p)

        try:
            while True:
                line = p.stdout.readline()
                if not line: break
                printd(line, distro)
        except Exception, e:
            printd("ERROR reading process output: %s"%e, distro)
            
        p.wait()
    
    t = threading.Thread(target=run, args=(distro, host))
    t.start()
        
def check():
    def checkVersionNumber():
        ver = os.environ['PACKAGE_VERSION']
        for num in ver.split("."):
            try:
                i = int(num)
            except ValueError:
                printd("ERROR: Invalid PACKAGE_VERSION: %s\n"%ver)
                sys.exit(1)
    
    checkVersionNumber()
    
def doBuild(distro):
    check()
    prepareEnv(distro)
    host = buildMachines[distro]['host']
    prepareBuildScrpits(host)
    startBuildThread(distro, host)
    
def main():
    def cleanup(processes, signal, stackframe):
        for p in processes:
            if p.returncode is None:
                printd("%s: Kill process %s with signal %s\n"%(p.distro, p, signal), p.distro)
                os.kill(p.pid, signal)
                
    def waitForAllThreadsStart(num):
        timeout = 60
        cnt = 0
        printd("There are %s processes are going to start\n"%num, "Supervisor")
        while len(processes) != num:
            time.sleep(1)
            printd("Waiting for processes start, should be %s, but %s\n"%(num, len(processes)), "Supervisor")
            cnt += 1
            if cnt >= timeout:
                raise Exception("Not all processes started, should be %s, but %s"%(num, len(processes)))
    
    def waitForAllThreadsEnd():
        while processes:
            retcodes = [ p.returncode for p in processes ]
            
            if all ([ r == 0 for r in retcodes ]):
                # all processes terminated normally
                # we exit the loop
                printd("all processes terminated normally\n", "supervisor")
                break
            
            if any(retcodes):
                for p in processes:
                    if p.returncode:
                        printd("Error, return code is %s"%p.returncode, p.distro)
                    cleanup(processes, SIGKILL, None)
                    raise subprocess.CalledProcessError(p.returncode, p.cmd)
            
            time.sleep(1)
    
    processNum = 0
    if os.environ['DO_DISTRO_PACKAGES'] == 'all':
        for distro in buildMachines:
            doBuild(distro)
            processNum += 1
    else:
        doBuild(os.environ['DO_DISTRO_PACKAGES'])
        processNum += 1
    
    waitForAllThreadsStart(processNum)
    waitForAllThreadsEnd()
        
if __name__ == '__main__':
    try:
        main()
        sys.exit(0)
    except Exception, e:
        printd(FormatErrMsg(e))
        sys.exit(1)