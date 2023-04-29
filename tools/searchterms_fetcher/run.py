import requests
import time
from string import ascii_lowercase
from itertools import combinations_with_replacement


asos_url = 'http://searchapi.asos.com/product/search/v1/suggestions?q=%s&store=1&lang=en&limit=10&channel=desktop-web'


def generate_query(depth, alphabet=ascii_lowercase):
    for i in range(depth):
        for c in combinations_with_replacement(alphabet, i + 1):
            q = ''.join(c)
            if not q.strip():
                continue
            yield q


def generate_terms_for_asos(depth, sleep_every=10):
    req_count = 0
    for q in generate_query(depth):
        if req_count % sleep_every == 0:
            time.sleep(2)
        headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36'}
        resp = requests.get(asos_url % q, headers=headers)
        req_count += 1
        if resp.status_code != 200:
            print('Error: ', resp.text)
            continue
        for sug in resp.json()['suggestionGroups'][0]['suggestions']:
            yield sug['searchTerm']


def save_search_terms():
    ct = 0
    term_set = set()
    with open('search_terms_asos.txt', 'w') as f:
        for t in generate_terms_for_asos(4):
            t = t.lower()
            if t in term_set:
                continue
            term_set.add(t)
            f.write(t)
            f.write('\n')
            ct += 1
            if ct % 20 == 0:
                print('Wrote %d' % ct)
    print('Wrote %d' % ct)


if __name__ == '__main__':
    save_search_terms()
