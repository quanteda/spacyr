# this script is coming from https://github.com/explosion/spaCy/issues/1508#issuecomment-343007014
from timeit import default_timer as timer
import spacy
import thinc.extra.datasets
import plac


def iter_phrases(texts):
	for text in texts:
		for i in range(0, len(text), 50):
			yield text[i : i + 50]

@plac.annotations(
	components=("Pipeline components", "positional"),
	use_pipe=("Whether to use nlp.pipe()", "flag", "p"),
	version=("Is this version 1.9?","flag","v")
)

def main(components='tagger,parser,ner', use_pipe=False, version=False):
	components = components.split(',')
	use_pipe = int(use_pipe)
	train, dev = thinc.extra.datasets.imdb()
	texts, labels = zip(*train)
	texts = texts[:200]
	nlp = spacy.load('en')
	start = timer()
	
	n_words = 0
	
	v = "2.0"
	
	if version:
	
		v = "1.10"
		
		disabled = [name for name in ['tagger','ner','parser'] 
					if name not in components]
	
		nlp.pipeline = []
		if 'tagger' in components:
			nlp.pipeline.append(nlp.tagger)
		if 'ner' in components:
			nlp.pipeline.append(nlp.entity)
		if 'parser' in components:
			nlp.pipeline.append(nlp.parser)
			
	else:
		disabled = [name for name in nlp.pipe_names if name not in components]
		nlp.disable_pipes(*disabled)
			
	if use_pipe:
		for doc in nlp.pipe(iter_phrases(texts)):
			n_words += len(doc)
	else:
		for phrase in iter_phrases(texts):
			doc = nlp(phrase)
			n_words += len(doc)

	seconds = timer() - start
	wps = n_words / seconds
	print('version=', v, 'components=', components, 'disabled=', disabled,
		  'use_pipe=', use_pipe, 'wps=', wps, 'words=', n_words,
		  'seconds=', seconds)


if __name__ == '__main__':
	plac.call(main)
