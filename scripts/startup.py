import os
import stat
import sys
from pathlib import Path
from subprocess import CalledProcessError, check_call

def setup():
    print("Starting Services")
    
    this_script = Path(os.path.realpath(sys.argv[0]))
    this_dir = this_script.parent
    setup_script = this_dir / "setup.sh"
    if setup_script.is_file():
        setup_script.chmod(stat.S_IREAD | stat.S_IWRITE | stat.S_IEXEC)
        try:
            check_call(str(setup_script), shell=True)
        except CalledProcessError as e:
            print("Unable to run {0}, error: '{1}'".format(setup_script, e))
    else:
        print("Unable to run {0}, file does not exist".format(setup_script))

if __name__ == '__main__':
    setup()