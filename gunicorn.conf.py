# gunicorn.conf.py
import os
import sys

def post_fork(server, worker):
    server.log.info("Worker spawned (pid: %s)", worker.pid)
    
    # Ensure the current path is in PYTHONPATH for the auto-instrumentation engine
    if "PYTHONPATH" not in os.environ:
        os.environ["PYTHONPATH"] = ":".join(sys.path)
        
    # Programmatically trigger the OpenTelemetry zero-code initialization
    from opentelemetry.instrumentation.auto_instrumentation import sitecustomize
