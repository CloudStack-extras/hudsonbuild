'''
Created on Jun 24, 2011

@author: frank
'''
from common import *
    
def prepareEnvVar():
    cfgPath = abspath(ENV_CFG_FILE)
    if not exists(cfgPath): raise Exception("Cannot find %s"%cfgPath)
    
    fd = open(cfgPath, 'r')
    envs = fd.readlines()
    fd.close()
    for env in envs:
        (key, value) = env.split("=")
        value = value.strip('\n')
        os.environ[key] = value
        printd("Set environment variable %s=%s\n" % (key, value))

def isDeb():
    return (os.environ["IS_DEB"] == "True")

def getResultDir():
    fd = open(os.environ["RESULT_DIR"], "r")
    resultDir = fd.readline()
    fd.close()
    return resultDir.strip('\n').strip()
    
def cloneSource():
    if isDeb():
        bash(['bash', abspath('clone.sh')])
    else:
        bash(['sh', abspath('clone.sh')])

# only after buildSource, environment variable has value  
def buildSource():
    def isPremium(f):
        premiumLabel = ['usage', 'premium', 'test', 'baremetal']
        for p in premiumLabel:
            if p in f: return True
        return False
        
    def getBuildParams():
        params = []
        if useWaf():
            excludeBranchs = ['2.2.beta1', '2.2.beta4', '2.1.4.kumquat', '2.1.banana',
                   '2.1.refactor', '2.1.vanilla', '2.1.x.217', '2.2.beta1.9', '2.1.6.kumquat',
                   '2.2.beta2', '2.2.beta3', 'fedorawork', 'hybrid', 'master.lime']
            
            buildTarget = os.environ['BUILDABLE_TARGET'].replace('tag-', '').replace('-', '.')
            prerelease = os.environ['LABEL_AS_PRERELEASE']
            buildNumber = os.environ['BUILD_NUMBER']
            pkgVer = os.environ['PACKAGE_VERSION']
            if prerelease and prerelease != 'false':
                params.append("--prerelease=%s"%buildTarget)
                params.append("--build-number=%s"%buildNumber)
                pkgVer = "%s.%s"%(pkgVer, buildNumber)
                
            if buildTarget not in excludeBranchs:
                params.append("--package-version=%s"%(pkgVer))
                
        else:
            pass
    
        return ' '.join(params)
    
    def buildRpm():
        bash(["sh", abspath("buildrpm.sh"), getBuildParams()])
    
    def buildDeb():
        bash(["bash", abspath("builddeb.sh"), getBuildParams()])
    
    def arrageResult(ext):
        resDir = abspath(getResultDir())
        printd("Packages locates at %s\n"%resDir)
        
        ossrpms = []
        premiumrpms = []
        for root, dirs, files in os.walk(abspath(resDir)):
            for f in files:
                if f.endswith(ext) and not isPremium(f):
                    ossrpms.append(join(root, f))
                elif f.endswith(ext) and isPremium(f):
                    premiumrpms.append(join(root, f))
        
        ossDir = join(resDir, 'oss')
        if not isdir(ossDir): os.makedirs(ossDir)
        for r in ossrpms: bash(["mv", r, ossDir])
        
        premiumDir = join(resDir, 'premium')
        if not isdir(premiumDir): os.makedirs(premiumDir)
        for r in premiumrpms: bash(["mv", r, premiumDir])
    
    
    if isDeb():
        buildDeb()
        arrageResult(".deb")
    else:
        buildRpm()
        arrageResult(".rpm")
        
        
def buildTarball():
    version = os.environ['PACKAGE_VERSION']
    distro = os.environ['DO_DISTRO_PACKAGES']
    if os.environ['LABEL_AS_PRERELEASE'] == 'true':
        version = "%s.%s"%(version, os.environ['BUILD_NUMBER'])
    else:
        version = "%s-1"%version
        
    if isDeb():
        if os.environ["BUILD_TARBALL"] == "oss&premium":
            bash(["bash", abspath("builddebtarball.sh"), "True", distro, version, "CloudStack-oss"])
            #bash(["sh", abspath("builddebtarball.sh"), "False", distro, version])
            printd("Debian build doesn't support premium tarball")
        elif os.environ["BUILD_TARBALL"] == "oss":
            bash(["bash", abspath("builddebtarball.sh"), "True", distro, version, "CloudStack-oss"])
        elif os.environ['BUILD_TARBALL'] == "mycloud-agent":
            bash(["bash", abspath("builddebtarball.sh"), "True", distro, version, "MyCloud"])
        elif os.environ["BUILD_TARBALL"] == "premium":
            #bash(["sh", abspath("builddebtarball.sh"), "False", distro, version])
            printd("Debian build doesn't support premium tarball")
        else:
            print("No need to build tarball")    
    else:
        if os.environ["BUILD_TARBALL"] == "oss&premium":
            bash(["sh", abspath("buildrpmtarball.sh"), "True", distro, version, "CloudStack-oss"])
            bash(["sh", abspath("buildrpmtarball.sh"), "False", distro, version, "CloudStack"])
        elif os.environ["BUILD_TARBALL"] == "oss":
            bash(["sh", abspath("buildrpmtarball.sh"), "True", distro, version, "CloudStack-oss"])
        elif os.environ["BUILD_TARBALL"] == "premium":
            bash(["sh", abspath("buildrpmtarball.sh"), "False", distro, version, "CloudStack"])
        else:
            print("No need to build tarball")


def postPackages():
    def postRpms():
        bash(["sh", "postrpms.sh"])
    
    def postDebs():
        bash(["bash", "postdebs.sh"])
        
    if isDeb():
        postDebs()
    else:
        postRpms()

        
def main():
    try:
        prepareEnvVar()
        cloneSource()
        buildSource()
        buildTarball()
        postPackages()
    except Exception, e:
        printd(FormatErrMsg(e))
        sys.exit(1)
            

if __name__ == '__main__':
    main()
    sys.exit(0)