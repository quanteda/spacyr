#!/usr/local/bin/python

# Sources:
#  Google universal: http://www.petrovi.de/data/universal.pdf
#  Penn treebank: http://web.mit.edu/6.863/www/PennTreebankTags.html
# Requires installation of spaCy: https://honnibal.github.io/spaCy/
#
# written by Paul Nulty, 19 March 2015

# command line arguments

#ap = argparse.ArgumentParser(description='Apply the spaCy part-of-speech tagger to a file.')

options = {}
options['tag'] =  option_tag

if not isinstance(texts, list):
  texts = [texts]
  
all_outs = []
outs = ""
count = 0
for line in texts:
	line = re.sub(' +',' ',line.strip())
	taggedWords = nlp(unicode(line), tag = True, parse = False)
	for w in taggedWords:
	  thisTag = w.tag_ if options['tag'] == "penn" else w.pos_
	  outs += " " + thisTag + "_" + w.orth_
	  count += 1
	  if count % 10 == 0:
	    all_outs.append(outs)
	    outs = ""
	outs += "[text_break]"

all_outs.append(outs)
