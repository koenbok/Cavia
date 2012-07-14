#!/bin/sh
mysql.server start
pg_ctl -D ~/postgres -l ~/postgres/server.log start