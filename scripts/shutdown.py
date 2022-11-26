from subprocess import CalledProcessError, check_call
from pathlib import Path

def setup():
    print("Disabling Services")

    home = Path.home()
    config_dir = home / "ccs-config.d"

    for service in ['gunicorn', 'nginx']:
        try:
            check_call("sudo service {} stop".format(service), shell=True)
        except CalledProcessError as e:
            print("Failed to stop service {0}, error: '{1}'".format(service, e))

        pathlist = Path(config_dir).glob(service + '*')
        for file in pathlist:
            try:
                file.unlink()
            except Exception as e:
                print("Failed to remove file {0}, error: '{1}'".format(file, e))

if __name__ == '__main__':
    setup()