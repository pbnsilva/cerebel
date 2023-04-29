'''
This script transforms the Deep Fashion dataset into Pascal VOC format.
This means:
    - creates an XML file per image with class, attributes and bounding boxes;
    - copies images
'''
import pickle
import json
import xml.etree.cElementTree as ET
from PIL import Image
import os
from xml.dom import minidom
from shutil import copyfile


DEEP_FASHION_BASE_PATH = '/Users/pedro/data/deep-fashion/category-attribute-prediction'
OUT_BASE_PATH = '/Users/pedro/data/cerebel-fashion-voc'


def get_data():
    # read categories
    category_types = {'1': 'upper-body', '2': 'lower-body', '3': 'full-body'}
    categories = []
    with open(f'{DEEP_FASHION_BASE_PATH}/Anno/list_category_cloth.txt', 'r') as f:
        i = 0
        for l in f:
            if i > 1:
                sp = l.split()
                categories.append((sp[0].strip().lower(), category_types[sp[1].strip()]))
            i += 1

    # read attributes
    attribute_types = {'1': 'texture', '2': 'fabric', '3': 'shape', '4': 'part', '5': 'style'}
    attributes = []
    with open(f'{DEEP_FASHION_BASE_PATH}/Anno/list_attr_cloth.txt', 'r') as f:
        i = 0
        for l in f:
            if i > 1:
                sp = l.strip().rsplit(' ', 1)
                attributes.append((sp[0].strip(), attribute_types[sp[1].strip()]))
            i += 1

    data = {}
    with open(f'{DEEP_FASHION_BASE_PATH}/Anno/list_category_img.txt', 'r') as f:
        i = 0
        for l in f:
            if i > 1:
                sp = l.split()
                data[sp[0].strip()] = {'orig_id': sp[0].strip(), 'id': 'img_%s' % str(i - 1).zfill(8), 'category': categories[int(sp[1].strip()) - 1]}
            i += 1

    with open(f'{DEEP_FASHION_BASE_PATH}/Anno/list_bbox.txt', 'r') as f:
        i = 0
        for l in f:
            if i > 1:
                sp = l.split(' ', 1)
                ipath = sp[0].strip()
                bbox = [str(int(v)) for v in sp[1].strip().split()]
                if ipath not in data:
                    print('Image not found:', ipath)
                    break
                data[ipath]['bbox'] = bbox
            i += 1

    with open(f'{DEEP_FASHION_BASE_PATH}/Anno/list_attr_img.txt', 'r') as f:
        i = 0
        for l in f:
            if i > 1:
                sp = l.split(' ', 1)
                ipath = sp[0].strip()
                ar = sp[1].strip().split()
                if ipath not in data:
                    print('Image not found:', ipath)
                    break
                ar = [attributes[i] for i in range(len(ar)) if ar[i] == '1']
                data[ipath]['attributes'] = ar
            i += 1
    return data


def load_pickle():
    return pickle.load(open('data.p', 'rb'))


def dump_pickle(data):
    pickle.dump(data, open('data.p', 'wb'))


def dump_json(data):
    with open('dump.jsonlines', 'w') as fout:
        for k in data:
            fout.write(json.dumps({'name': k, 'id': data[k]['id'], 'category': data[k]['category'], 'attributes': data[k]['attributes'], 'bbox': data[k]['bbox']}))
            fout.write('\n')


def write_xml_el(el):
    root = ET.Element("annotation")
    ET.SubElement(root, 'folder').text = 'cerebel-fashion-voc'
    ET.SubElement(root, 'filename').text = '%s.jpg' % el['id']

    img = Image.open(os.path.join(f'{DEEP_FASHION_BASE_PATH}/Img', el['orig_id']))
    width, height = img.size

    size = ET.SubElement(root, 'size')
    ET.SubElement(size, 'width').text = str(width)
    ET.SubElement(size, 'height').text = str(height)
    ET.SubElement(size, 'depth').text = '3'

    obj = ET.SubElement(root, 'object')
    ET.SubElement(obj, 'name').text = el['category'][0]
    ET.SubElement(obj, 'category_type').text = el['category'][1]

    attr = ET.SubElement(obj, 'attributes')
    for item in el['attributes']:
        at = ET.SubElement(attr, 'attribute')
        ET.SubElement(at, 'value').text = item[0]
        ET.SubElement(at, 'type').text = item[1]

    bbox = ET.SubElement(obj, 'bndbox')
    ET.SubElement(bbox, 'xmin').text = el['bbox'][0]
    ET.SubElement(bbox, 'ymin').text = el['bbox'][1]
    ET.SubElement(bbox, 'xmax').text = el['bbox'][2]
    ET.SubElement(bbox, 'ymax').text = el['bbox'][3]

    rough_string = ET.tostring(root, 'utf-8')
    reparsed = minidom.parseString(rough_string)
    with open(os.path.join(f'{OUT_BASE_PATH}/Annotations', '%s.xml' % el['id']), 'w') as fout:
        fout.write(reparsed.toprettyxml(indent="  "))


def write_xml(data):
    i = 0
    total_count = len(data)
    for k, v in data.items():
        write_xml_el(v)
        i += 1
        if i % 50000 == 0:
            print(100.0 * i / total_count)


def write_sets(data):
    train_out = open(f'{OUT_BASE_PATH}/ImageSets/Main/train.txt', 'w')
    test_out = open(f'{OUT_BASE_PATH}/ImageSets/Main/test.txt', 'w')
    val_out = open(f'{OUT_BASE_PATH}/ImageSets/Main/val.txt', 'w')
    trainval_out = open(f'{OUT_BASE_PATH}/ImageSets/Main/trainval.txt', 'w')
    with open(f'{DEEP_FASHION_BASE_PATH}/Eval/list_eval_partition.txt', 'r') as f:
        i = 0
        for l in f:
            if i > 1:
                sp = l.split()
                ipath = sp[0].strip()
                tp = sp[1].strip()
                if ipath not in data:
                    print('Image not found:', ipath)
                    break
                if tp == 'train':
                    train_out.write('%s\n' % data[ipath]['id'])
                    trainval_out.write('%s\n' % data[ipath]['id'])
                elif tp == 'test':
                    test_out.write('%s\n' % data[ipath]['id'])
                elif tp == 'val':
                    val_out.write('%s\n' % data[ipath]['id'])
                    trainval_out.write('%s\n' % data[ipath]['id'])
            i += 1
    val_out.close()
    test_out.close()
    trainval_out.close()
    train_out.close()


def copy_images(data):
    i = 0
    total_count = len(data)
    for k in data:
        copyfile(os.path.join(f'{DEEP_FASHION_BASE_PATH}/Img', k),
                 f'{OUT_BASE_PATH}/JPEGImages/%s.jpg' % data[k]['id'])
        i += 1
        if i % 50000 == 0:
            print(100.0 * i / total_count)


# data = get_data()
# dump_pickle(data)
print('Loading...')
data = load_pickle()
print('Writing sets...')
write_sets(data)
print('Writing XML...')
write_xml(data)
print('Copying images...')
copy_images(data)
