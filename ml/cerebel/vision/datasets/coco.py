import os
import numpy as np
import cv2
import torch
import torch.utils.data as data
from PIL import Image


class CocoDetection(data.Dataset):
    """`MS Coco Captions <http://mscoco.org/dataset/#detections-challenge2016>`_ Dataset.
    Args:
        root (string): Root directory where images are downloaded to.
        annFile (string): Path to json annotation file.
        transform (callable, optional): A function/transform that  takes in an PIL image
            and returns a transformed version. E.g, ``transforms.ToTensor``
        target_transform (callable, optional): A function/transform that takes in the
            target and transforms it.
    """

    def __init__(self, root, annFile, transform=None, target_transform=None):
        from pycocotools.coco import COCO
        self.root = root
        self.coco = COCO(annFile)
        self.ids = list(self.coco.imgs.keys())
        self.transform = transform
        self.target_transform = target_transform

    def __getitem__(self, index):
        """
        Args:
            index (int): Index
        Returns:
            tuple: Tuple (image, target). target is the object returned by ``coco.loadAnns``.
        """
        coco = self.coco
        img_id = self.ids[index]
        ann_ids = coco.getAnnIds(imgIds=img_id)
        target = coco.loadAnns(ann_ids)

        path = coco.loadImgs(img_id)[0]['file_name']
        img = cv2.imread(os.path.join(self.root, path))
        height, width, _ = img.shape

        if self.target_transform is not None:
            target = self.target_transform(target, width, height)

        if self.transform is not None:
            target = np.array(target)
            img, boxes, labels = self.transform(img, target[:, :4], target[:, 4])
            # to rgb
            img = img[:, :, (2, 1, 0)]  # TODO why this??? bgr better results?
            target = np.hstack((boxes, np.expand_dims(labels, axis=1)))

        return torch.from_numpy(img).permute(2, 0, 1), target

    def pull_image(self, index):
        '''Returns the original image object at index in PIL form

        Argument:
            index (int): index of img to show
        Return:
            PIL img
        '''
        coco = self.coco
        img_id = self.ids[index]
        path = coco.loadImgs(img_id)[0]['file_name']
        return cv2.imread(os.path.join(self.root, path), cv2.IMREAD_COLOR)

    def pull_anno(self, index):
        '''Returns the original annotation of image at index

        Argument:
            index (int): index of img to get annotation of
        Return:
            list:  [img_id, [(label, bbox coords),...]]
                eg: ('001718', [('dog', (96, 13, 438, 332))])
        '''
        coco = self.coco
        img_id = self.ids[index]
        ann_ids = coco.getAnnIds(imgIds=img_id)
        target = coco.loadAnns(ann_ids)
        gt = self.target_transform(target, 1, 1)
        return img_id, gt

    def __len__(self):
        return len(self.ids)


class CocoAnnotationTransform(object):
    """Transforms a VOC annotation into a Tensor of bbox coords and label index
    Initilized with a dictionary lookup of classnames to indexes

    Arguments:
        keep_difficult (bool, optional): keep difficult instances or not
            (default: False)
        height (int): height
        width (int): width
    """

    def __init__(self, keep_difficult=False):
        self.keep_difficult = keep_difficult

    def __call__(self, target, width, height):
        """
        Arguments:
            target (annotation) : the target annotation to be made usable
        Returns:
            a list containing lists of bounding boxes  [bbox coords, class name]
        """
        res = []
        for an in target:
            xmin, ymin, w, h = an['bbox']
            res.append([xmin / width,
                        ymin / height,
                        (xmin + w) / width,
                        (ymin + h) / height,
                        an['category_id']])  # an['category_id']
        return res  # [[xmin, ymin, xmax, ymax, label_ind], ... ]


class CocoClassification(data.Dataset):
    """`MS Coco Captions <http://mscoco.org/dataset/#detections-challenge2016>`_ Dataset.
    Args:
        root (string): Root directory where images are downloaded to.
        annFile (string): Path to json annotation file.
        transform (callable, optional): A function/transform that  takes in an PIL image
            and returns a transformed version. E.g, ``transforms.ToTensor``
        target_transform (callable, optional): A function/transform that takes in the
            target and transforms it.
    """

    def __init__(self, root, annFile, task, transform=None, target_transform=None):
        from pycocotools.coco import COCO
        self.root = root
        self.task = task
        self.coco = COCO(annFile)
        self.ids = list(self.coco.imgs.keys())
        self.transform = transform
        self.target_transform = target_transform

    def __getitem__(self, index):
        """
        Args:
            index (int): Index
        Returns:
            tuple: Tuple (image, target). target is the object returned by ``coco.loadAnns``.
        """
        coco = self.coco
        img_id = self.ids[index]
        ann_ids = coco.getAnnIds(imgIds=img_id)
        target = coco.loadAnns(ann_ids)
        path = coco.loadImgs(img_id)[0]['file_name']

        img = Image.open(os.path.join(self.root, path)).convert('RGB')

        if self.task == 'category':
            if 'bbox' in target[0]:
                xmin, ymin, w, h = target[0]['bbox']
                img = img.crop((xmin, ymin, xmin + w, ymin + h))
            target = target[0]['category_id']
        elif self.task == 'isfashion':
            target = int(target[0].get('is_fashion', False))
        elif self.task == 'hasface':
            target = int(len(target[0].get('face_bbox', [])) > 0)
        elif self.task == 'texture':
            if 'bbox' in target[0]:
                xmin, ymin, w, h = target[0]['bbox']
                img = img.crop((xmin, ymin, xmin + w, ymin + h))
            target = target[0]['texture_ids'][0]

        if self.transform is not None:
            img = self.transform(img)

        return img, target

    def __len__(self):
        return len(self.ids)
