#!/bin/bash

# create virtualenv
deactivate
virtualenv -p /usr/bin/python2.7 --system-site-packages env
source testenv/bin/activate

# Python dependencies
sudo pip install --upgrade pip
sudo pip install spacy
sudo python -m spacy download en

