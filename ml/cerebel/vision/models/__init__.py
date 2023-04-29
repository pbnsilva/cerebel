import torch
import numpy as np
from .utils import load_url
from .ssd import build_ssd
from .inception import Inception3Base
from cerebel.vision.datasets import CATEGORY_CLASSES, SSD_CATEGORY_CLASSES,  IS_FASHION_CLASSES, TEXTURE_CLASSES, HAS_FACE_CLASSES


# TODO this cannot be public!!
model_urls = {
    'fashion_category_ssd': 'https://storage.googleapis.com/data.cerebel.io/models/vision/category_ssd_20171127.pth',
    'fashion_inceptionv3_notop_nocuda': 'https://storage.googleapis.com/data.cerebel.io/models/vision/fashion_inceptionv3_notop_nocuda_2018320.pth',
}

task_class_count = {
    'category': len(CATEGORY_CLASSES),
    'isfashion': len(IS_FASHION_CLASSES),
    'texture': len(TEXTURE_CLASSES),
    'hasface': len(HAS_FACE_CLASSES),
 }


def load_ssd(model_dir, use_cuda=False):
    model = build_ssd('test', 300, len(SSD_CATEGORY_CLASSES) + 1)
    model.load_state_dict(load_url(model_urls['fashion_category_ssd'],
                                   model_dir,
                                   use_cuda=use_cuda))
    return model


def save(model, dst, top_only=False):
    if top_only:
        new_state = {k[10:]: v for k, v in model.items() if k.startswith('module.fc')}
    else:
        new_state = {k[7:]: v for k, v in model.items()}
    torch.save(new_state, dst)


def softmax(x):
    e_x = np.exp(x - np.max(x))
    return e_x / e_x.sum(axis=0)
