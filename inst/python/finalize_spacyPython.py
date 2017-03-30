#!/usr/local/bin/python

import gc

if "spobj" in locals():
    del spobj

del nlp
gc.collect()
