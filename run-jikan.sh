#!/usr/bin/env bash
cd app
chmod -R a+w storage/
php -S 0.0.0.0:8000 -t public
