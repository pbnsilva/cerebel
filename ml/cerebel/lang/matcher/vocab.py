import io
import spacy
from operator import itemgetter
from spacy.matcher import Matcher
from collections import Counter
from cerebel.lang.matcher import BaseMatcher


class VocabEntityMatcher(BaseMatcher):
    def __init__(self, model_path):
        self.nlp = spacy.load('en')
        vocab = self._load_vocab(model_path)
        self._matcher = self._load_matcher(vocab)

    def match(self, doc):
        entities = []
        prefix_count = Counter()
        proc_doc = self.nlp(doc.lower())
        last_start, last_end = -1, -1
        last_pref = ''
        for match in sorted(self._matcher(proc_doc), key=itemgetter(1)):
            start, end = match[1], match[2]
            if end > last_end:
                if start == last_start:
                    entities.pop()
                    entities.append((self.nlp.vocab.strings[match[0]], start, end, proc_doc[start:end].text))
                    prefix_count[self.nlp.vocab.strings[match[0]][:3]] += 1
                elif start > last_start:
                    if last_pref == self.nlp.vocab.strings[match[0]][:3]:  # TODO this is very hacky!!
                        # entities.pop()
                        prefix_count[self.nlp.vocab.strings[match[0]][:3]] -= 1
                    else:
                        entities.append((self.nlp.vocab.strings[match[0]], start, end, proc_doc[start:end].text))
                        prefix_count[self.nlp.vocab.strings[match[0]][:3]] += 1
            elif last_pref != self.nlp.vocab.strings[match[0]][:3]:
                entities.append((self.nlp.vocab.strings[match[0]], start, end, proc_doc[start:end].text))
                prefix_count[self.nlp.vocab.strings[match[0]][:3]] += 1
            last_start, last_end = start, end
            last_pref = self.nlp.vocab.strings[match[0]][:3]

        rm_idx = set()
        last_start, last_end = -1, -1
        last_pref = ''
        for i, ent in enumerate(entities):
            pref = ent[0][:6]
            start, end = ent[1], ent[2]
            if last_start == start and last_end == end and last_pref != pref:
                if prefix_count[last_pref] > prefix_count[pref]:
                    rm_idx.add(i-1)
                else:
                    rm_idx.add(i)
            last_start, last_end, last_pref = start, end, pref

        return [e for i, e in enumerate(entities) if i not in rm_idx]

    def _load_matcher(self, vocab):
        matcher = Matcher(self.nlp.vocab)
        for eid, vocab in vocab:
            proc_tokens = []
            for tokens in vocab:
                tokens_proc = self.nlp(tokens)
                proc_tokens.append([{'LEMMA': t.lemma_} for t in tokens_proc])
            matcher.add(eid, None, *proc_tokens)
        return matcher

    def _load_vocab(self, model_path):
        vocab = []
        with io.open(model_path, mode='r', encoding='utf8') as f:
            for l in f:
                entity_id, values = l.strip().split('\t')
                vocab.append((entity_id, values.split(',')))
        return vocab
