import spacy
from .w2n import word_to_num, american_number_system
from spacy.matcher import Matcher
from cerebel.lang.matcher import BaseMatcher
from enum import Enum


class MatchKind(Enum):
    BETWEEN_EUR = 1
    LESS_THAN_EUR = 2
    MORE_THAN_EUR = 3
    AROUND_EUR = 4
    BETWEEN_USD = 5
    LESS_THAN_USD = 6
    MORE_THAN_USD = 7
    AROUND_USD = 8
    BETWEEN_GBP = 9
    LESS_THAN_GBP = 10
    MORE_THAN_GBP = 11
    AROUND_GBP = 12


class PriceRangeMatcher(BaseMatcher):

    def __init__(self):
        self._nlp = spacy.load('en')
        self._matcher = self._load_matcher()

    def match(self, doc):
        matches = []
        min_delta = 0
        match_idx = 0
        doc = self._word_to_num(self._nlp(doc))
        doc = self._nlp(doc)
        digits = sorted([int(v.text) for v in doc if v.is_digit])
        for i, (match_id, start, end) in enumerate(self._matcher(doc)):
            if start - end < min_delta:
                min_delta = start - end
                match_idx = i
            if match_id == MatchKind.BETWEEN_EUR.value:
                matches.append(('EUR', [('gte', digits[0]), ('lte', digits[1])]))
            elif match_id == MatchKind.BETWEEN_USD.value:
                matches.append(('USD', [('gte', digits[0]), ('lte', digits[1])]))
            elif match_id == MatchKind.BETWEEN_GBP.value:
                matches.append(('GBP', [('gte', digits[0]), ('lte', digits[1])]))
            elif match_id == MatchKind.LESS_THAN_EUR.value:
                matches.append(('EUR', [('lte', digits[0])]))
            elif match_id == MatchKind.LESS_THAN_USD.value:
                matches.append(('USD', [('lte', digits[0])]))
            elif match_id == MatchKind.LESS_THAN_GBP.value:
                matches.append(('GBP', [('lte', digits[0])]))
            elif match_id == MatchKind.MORE_THAN_EUR.value:
                matches.append(('EUR', [('gte', digits[0])]))
            elif match_id == MatchKind.MORE_THAN_USD.value:
                matches.append(('USD', [('gte', digits[0])]))
            elif match_id == MatchKind.MORE_THAN_GBP.value:
                matches.append(('GBP', [('gte', digits[0])]))
            elif match_id == MatchKind.AROUND_EUR.value:
                matches.append(('EUR', [('eq', digits[0])]))
            elif match_id == MatchKind.AROUND_USD.value:
                matches.append(('USD', [('eq', digits[0])]))
            elif match_id == MatchKind.AROUND_GBP.value:
                matches.append(('GBP', [('eq', digits[0])]))
        return matches[match_idx] if len(matches) > 0 else None

    def _word_to_num(self, doc):
        words = []
        buf = []
        nset = set(american_number_system.keys()).union({',', 'and'})
        for w in doc:
            if w.text in nset:
                buf.append(w.text)
            else:
                if buf:
                    try:
                        num = word_to_num(' '.join(buf))
                        words.append(str(num))
                    except ValueError:
                        words += buf
                buf = []
                words.append(w.text)
        if buf:
            try:
                num = word_to_num(' '.join(buf))
                words.append(str(num))
            except ValueError:
                words += buf
        return ' '.join(words)

    def _load_matcher(self):
        matcher = Matcher(self._nlp.vocab)
        matcher.add(MatchKind.BETWEEN_EUR.value, None, [{'LOWER': 'from'},
                                                        {'IS_DIGIT': True},
                                                        {'LEMMA': 'euro', 'OP': '*'},
                                                        {'LOWER': 'to'},
                                                        {'IS_DIGIT': True},
                                                        {'LEMMA': 'euro', 'OP': '*'}])
        matcher.add(MatchKind.BETWEEN_EUR.value, None, [{'LOWER': 'between'},
                                                        {'IS_DIGIT': True},
                                                        {'LEMMA': 'euro', 'OP': '*'},
                                                        {'LOWER': 'and'},
                                                        {'IS_DIGIT': True},
                                                        {'LEMMA': 'euro', 'OP': '*'}])
        matcher.add(MatchKind.BETWEEN_USD.value, None, [{'LOWER': 'from'},
                                                        {'IS_DIGIT': True},
                                                        {'LEMMA': 'dollar', 'OP': '*'},
                                                        {'LOWER': 'to'},
                                                        {'IS_DIGIT': True},
                                                        {'LEMMA': 'dollar', 'OP': '*'}])
        matcher.add(MatchKind.BETWEEN_USD.value, None, [{'LOWER': 'between'},
                                                        {'IS_DIGIT': True},
                                                        {'LEMMA': 'dollar', 'OP': '*'},
                                                        {'LOWER': 'and'},
                                                        {'IS_DIGIT': True},
                                                        {'LEMMA': 'dollar', 'OP': '*'}])
        matcher.add(MatchKind.BETWEEN_GBP.value, None, [{'LOWER': 'from'},
                                                        {'IS_DIGIT': True},
                                                        {'LEMMA': 'pound', 'OP': '*'},
                                                        {'LOWER': 'to'},
                                                        {'IS_DIGIT': True},
                                                        {'LEMMA': 'pound', 'OP': '*'}])
        matcher.add(MatchKind.BETWEEN_GBP.value, None, [{'LOWER': 'between'},
                                                        {'IS_DIGIT': True},
                                                        {'LEMMA': 'pound', 'OP': '*'},
                                                        {'LOWER': 'and'},
                                                        {'IS_DIGIT': True},
                                                        {'LEMMA': 'pound', 'OP': '*'}])
        matcher.add(MatchKind.LESS_THAN_EUR.value, None, [{'LOWER': 'less'},
                                                          {'LOWER': 'than'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'euro', 'OP': '*'}])
        matcher.add(MatchKind.LESS_THAN_EUR.value, None, [{'LOWER': 'cheaper'},
                                                          {'LOWER': 'than'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'euro', 'OP': '*'}])
        matcher.add(MatchKind.LESS_THAN_EUR.value, None, [{'LOWER': 'not'},
                                                          {'LOWER': 'more'},
                                                          {'LOWER': 'than'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'euro', 'OP': '*'}])
        matcher.add(MatchKind.LESS_THAN_EUR.value, None, [{'LOWER': 'at'},
                                                          {'LOWER': 'most'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'euro', 'OP': '*'}])
        matcher.add(MatchKind.LESS_THAN_USD.value, None, [{'LOWER': 'less'},
                                                          {'LOWER': 'than'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'dollar', 'OP': '*'}])
        matcher.add(MatchKind.LESS_THAN_USD.value, None, [{'LOWER': 'cheaper'},
                                                          {'LOWER': 'than'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'dollar', 'OP': '*'}])
        matcher.add(MatchKind.LESS_THAN_USD.value, None, [{'LOWER': 'not'},
                                                          {'LOWER': 'more'},
                                                          {'LOWER': 'than'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'dollar', 'OP': '*'}])
        matcher.add(MatchKind.LESS_THAN_USD.value, None, [{'LOWER': 'at'},
                                                          {'LOWER': 'most'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'dollar', 'OP': '*'}])
        matcher.add(MatchKind.LESS_THAN_GBP.value, None, [{'LOWER': 'less'},
                                                          {'LOWER': 'than'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'pound', 'OP': '*'}])
        matcher.add(MatchKind.LESS_THAN_GBP.value, None, [{'LOWER': 'cheaper'},
                                                          {'LOWER': 'than'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'pound', 'OP': '*'}])
        matcher.add(MatchKind.LESS_THAN_GBP.value, None, [{'LOWER': 'not'},
                                                          {'LOWER': 'more'},
                                                          {'LOWER': 'than'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'pound', 'OP': '*'}])
        matcher.add(MatchKind.LESS_THAN_GBP.value, None, [{'LOWER': 'at'},
                                                          {'LOWER': 'most'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'pound', 'OP': '*'}])

        matcher.add(MatchKind.MORE_THAN_EUR.value, None, [{'LOWER': 'more'},
                                                          {'LOWER': 'than'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'euro', 'OP': '*'}])
        matcher.add(MatchKind.MORE_THAN_EUR.value, None, [{'LOWER': 'at'},
                                                          {'LOWER': 'least'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'euro', 'OP': '*'}])
        matcher.add(MatchKind.MORE_THAN_EUR.value, None, [{'LOWER': 'not'},
                                                          {'LOWER': 'less'},
                                                          {'LOWER': 'than'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'euro', 'OP': '*'}])
        matcher.add(MatchKind.MORE_THAN_USD.value, None, [{'LOWER': 'more'},
                                                          {'LOWER': 'than'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'dollar', 'OP': '*'}])
        matcher.add(MatchKind.MORE_THAN_USD.value, None, [{'LOWER': 'at'},
                                                          {'LOWER': 'least'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'dollar', 'OP': '*'}])
        matcher.add(MatchKind.MORE_THAN_USD.value, None, [{'LOWER': 'not'},
                                                          {'LOWER': 'less'},
                                                          {'LOWER': 'than'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'dollar', 'OP': '*'}])
        matcher.add(MatchKind.MORE_THAN_GBP.value, None, [{'LOWER': 'more'},
                                                          {'LOWER': 'than'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'pound', 'OP': '*'}])
        matcher.add(MatchKind.MORE_THAN_GBP.value, None, [{'LOWER': 'at'},
                                                          {'LOWER': 'least'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'pound', 'OP': '*'}])
        matcher.add(MatchKind.MORE_THAN_GBP.value, None, [{'LOWER': 'not'},
                                                          {'LOWER': 'less'},
                                                          {'LOWER': 'than'},
                                                          {'IS_DIGIT': True},
                                                          {'LEMMA': 'pound', 'OP': '*'}])
        matcher.add(MatchKind.AROUND_EUR.value, None, [{'LOWER': 'around'},
                                                       {'IS_DIGIT': True},
                                                       {'LEMMA': 'euro', 'OP': '*'}])
        matcher.add(MatchKind.AROUND_EUR.value, None, [{'IS_DIGIT': True},
                                                       {'LEMMA': 'euro', 'OP': '*'}])
        matcher.add(MatchKind.AROUND_USD.value, None, [{'LOWER': 'around'},
                                                       {'IS_DIGIT': True},
                                                       {'LEMMA': 'dollar', 'OP': '*'}])
        matcher.add(MatchKind.AROUND_USD.value, None, [{'IS_DIGIT': True},
                                                       {'LEMMA': 'dollar', 'OP': '*'}])
        matcher.add(MatchKind.AROUND_GBP.value, None, [{'LOWER': 'around'},
                                                       {'IS_DIGIT': True},
                                                       {'LEMMA': 'pound', 'OP': '*'}])
        matcher.add(MatchKind.AROUND_GBP.value, None, [{'IS_DIGIT': True},
                                                       {'LEMMA': 'pound', 'OP': '*'}])
        return matcher
