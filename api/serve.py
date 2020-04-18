#!/usr/bin/python -u

import os
import web
import json
import sys
import prometheus_client
import time
import traceback
import subprocess
import format_data

CHECK_ALIVE_PATH = '/alive'
CHECK_READY_PATH = '/ready'
CACHE = {}

# Instrumentation for monitoring
def before_request():
  web.start_time = time.time()


def after_request():
  params = web.ctx
  if params.path not in (CHECK_ALIVE_PATH, CHECK_READY_PATH):
    latency = time.time() - web.start_time
    REQUEST_COUNT.labels(params.method, params.path, params.status).inc()
    REQUEST_LATENCY.labels(params.method, params.path).observe(latency)


def exec_query(query, read=False):
  conn = psycopg2.connect(host='db', user='postgres', password='postgres')
  conn.autocommit = True
  cur = conn.cursor()
  try:
    cur.execute(query)
  except Exception as e:
    traceback.print_exc()
    return web.badrequest(message=str(e))
  finally:
    conn.close()
  if read:
    return cur.fetchall()
  else:
    return True


class covid:
  def GET(self):
    params = web.input(refresh=False)
    global CACHE
    if params.refresh or not CACHE:
      if 0 != subprocess.call(os.getcwd() + '/export_data.sh', shell=True):
        print('error refreshing data')
        raise Exception
      CACHE = format_data.get_data()
    return json.dumps(CACHE, sort_keys=True)


class checkAlive:
  def GET(self):
    return ''  # if exec_query('SELECT NULL') else web.internalerror()


class checkReady:
  def GET(self):
    return ''  # if exec_query('SELECT NULL') else web.internalerror()


if __name__ == '__main__':

  # map uris to classes
  urls = (
    '/covid', 'covid',
    CHECK_ALIVE_PATH, 'checkAlive',
    CHECK_READY_PATH, 'checkReady'
  )
  app = web.application(urls, globals())

  # collect and expose request/response metrics
  if os.environ.get('EXPOSE_METRICS', 'true') != 'false':
    REQUEST_COUNT = prometheus_client.Counter('requests', 'Request Count', ['method', 'path', 'status'])
    REQUEST_LATENCY = prometheus_client.Histogram('request_latency', 'Request Latency', ['method', 'path'])
    app.add_processor(web.loadhook(before_request))
    app.add_processor(web.unloadhook(after_request))
    prometheus_client.start_http_server(8000)

  # start http server
  web.httpserver.runsimple(app.wsgifunc(), ('0.0.0.0', 8080))
