import io
import spacy
from spacy.matcher import PhraseMatcher
from cerebel.lang.matcher import BaseMatcher


class BrandMatcher(BaseMatcher):
    def __init__(self, model_path):
        self.nlp = spacy.load('en')
        self._matcher = self._load_matcher(model_path)

    def match(self, doc):
        proc_doc = self.nlp(doc.lower())
        entities = []
        last_start, last_end = -1, -1
        for match in self._matcher(proc_doc):
            start, end = match[1], match[2]
            if end > last_end:
                if start == last_start:
                    entities.pop()
                    entities.append((self.nlp.vocab.strings[match[0]], proc_doc[start:end].text, start, end))
                elif start > last_start:
                    entities.append((self.nlp.vocab.strings[match[0]], proc_doc[start:end].text, start, end))
            last_start, last_end = start, end
        return entities

    def _load_matcher(self, model_path):
        matcher = PhraseMatcher(self.nlp.vocab)
        with io.open(model_path, mode='r', encoding='utf8') as f:
            for l in f:
                label, vocab = l.strip().split('\t')
                matcher.add(label, None, *[self.nlp(v) for v in vocab.split(',')])
        return matcher
