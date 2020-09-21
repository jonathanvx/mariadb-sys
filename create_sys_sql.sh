#!/bin/bash

CAT before_setup.sql > maria_sys.sql

CAT ./views/*.sql | grep -v "\-\- " > maria_sys.sql
