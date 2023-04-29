import os
import sys
import shutil
import requests
from urllib.parse import urlparse
import torch


def load_url(url, model_dir='/models', use_cuda=False):
    if not os.path.exists(model_dir):
        os.makedirs(model_dir)
    parts = urlparse(url)
    filename = os.path.basename(parts.path)
    cached_file = os.path.join(model_dir, filename)
    if not os.path.exists(cached_file):
        sys.stderr.write('Downloading: "{}" to {}\n'.format(url, cached_file))
        _download_url_to_file(url, cached_file)
    map_location = None
    if not use_cuda:
        map_location = lambda storage, loc: storage
    return torch.load(cached_file, map_location=map_location)


def _download_url_to_file(url, dst):
    r = requests.get(url, stream=True)
    with open(dst, 'wb') as f:
        shutil.copyfileobj(r.raw, f)
