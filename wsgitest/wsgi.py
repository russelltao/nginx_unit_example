import os
import sys

def application(environ, start_response):
    body = "Hello World@wsgi\n".encode()

    start_response('200', [('Content-Length', str(len(body)))])
    return [body]
