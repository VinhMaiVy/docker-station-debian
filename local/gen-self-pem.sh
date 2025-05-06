#! /bin/bash

openssl req -new -x509 -days 365 -nodes -out selfpem -keyout selfpem
