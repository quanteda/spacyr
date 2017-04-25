# this script remove spobj and also spacyNLP to free up memory

if "spobj" in locals():
    del spobj

if "nlp" in locals():
    del nlp

gc.collect()
