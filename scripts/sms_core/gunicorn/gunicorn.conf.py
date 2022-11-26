import multiprocessing
from sys import platform
from os import path

# Basic settings

bind = "unix:/tmp/gunicorn.sock"
loglevel = "debug"

workers = multiprocessing.cpu_count() * 2 + 1

# Logging settings
accesslog = path.expanduser("LOG_DIR/gunicorn/access.log")
errorlog = path.expanduser("LOG_DIR/gunicorn/error.log")
capture_output = True

# Hooks
# See https://docs.gunicorn.org/en/stable/settings.html#server-hooks for more
def on_starting(server):
    pass

