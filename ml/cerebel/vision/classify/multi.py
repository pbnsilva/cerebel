import torch
import torch.nn as nn
import torchvision.transforms as transforms
from enum import Enum
from cerebel.vision.models import Inception3Base
from cerebel.vision.models.utils import load_url
from cerebel.vision.models import softmax
from cerebel.vision.datasets import CATEGORY_CLASSES,  IS_FASHION_CLASSES, TEXTURE_CLASSES, HAS_FACE_CLASSES


# TODO this cannot be public!!
model_urls = {
    'fashion_inceptionv3_notop_nocuda': 'https://storage.googleapis.com/data.cerebel.io/models/vision/fashion_inceptionv3_notop_nocuda_2018320.pth',
    'fashion_category_clf_nocuda': 'https://storage.googleapis.com/data.cerebel.io/models/vision/fashion_category_clf_nocuda_2018320.pth',
    'fashion_isfashion_clf_nocuda': 'https://storage.googleapis.com/data.cerebel.io/models/vision/fashion_isfashion_clf_nocuda_20171124.pth',
    'fashion_texture_clf_nocuda': 'https://storage.googleapis.com/data.cerebel.io/models/vision/fashion_texture_clf_nocuda_20171128.pth',
    'fashion_hasface_clf_nocuda': 'https://storage.googleapis.com/data.cerebel.io/models/vision/fashion_hasface_clf_2018421_nocuda.pth',
}


class MultiClassifier:
    class Tasks(Enum):
        CATEGORY_PREDICTION = 0
        IS_FASHION_PREDICTION = 1
        HAS_FACE_PREDICTION = 2
        TEXTURE_PREDICTION = 3

    _task_names = {
        Tasks.CATEGORY_PREDICTION: 'category',
        Tasks.IS_FASHION_PREDICTION: 'isfashion',
        Tasks.HAS_FACE_PREDICTION: 'hasface',
        Tasks.TEXTURE_PREDICTION: 'texture',
    }

    _task_class_count = {
        Tasks.CATEGORY_PREDICTION: len(CATEGORY_CLASSES),
        Tasks.IS_FASHION_PREDICTION: len(IS_FASHION_CLASSES),
        Tasks.HAS_FACE_PREDICTION: len(HAS_FACE_CLASSES),
        Tasks.TEXTURE_PREDICTION: len(TEXTURE_CLASSES),
    }

    _task_labels = {
        Tasks.CATEGORY_PREDICTION: CATEGORY_CLASSES,
        Tasks.IS_FASHION_PREDICTION: IS_FASHION_CLASSES,
        Tasks.HAS_FACE_PREDICTION: HAS_FACE_CLASSES,
        Tasks.TEXTURE_PREDICTION: TEXTURE_CLASSES,
    }

    def __init__(self, models_path, tasks, use_cuda=False):
        self.models_path = models_path
        self.tasks = tasks
        self.use_cuda = use_cuda
        self._clf_net = self._load_clf_net()
        self._clf_transform = transforms.Compose([transforms.Resize(299), transforms.CenterCrop(299), transforms.ToTensor()])

    def predict(self, image, tasks, max_results, output_embeddings=False):
        x = torch.autograd.Variable(self._clf_transform(image).unsqueeze(0))
        clf_out = self._clf_net(x, tasks=tasks)

        tasks_out = []
        for i in range(len(tasks)):
            out = clf_out[i+1].data
            a, b = out.topk(max_results[i])
            b = b[0].numpy()
            confidences = softmax(a[0].numpy())
            tasks_out.append([(self._task_labels[tasks[i]][b[j]], confidences[j]) for j in range(len(b))])

        if output_embeddings:
            return [clf_out[0].data.numpy()[0]] + tasks_out

        return tasks_out

    def predict_bulk(self, images, tasks, max_results, output_embeddings=False):
        X = torch.FloatTensor(len(images), 3, 299, 299)
        for i in range(len(images)):
            X[i] = self._clf_transform(images[i])
        X = torch.autograd.Variable(X)
        clf_out = self._clf_net(X, tasks=tasks)

        res = []
        for i in range(len(images)):
            tasks_out = []
            for j in range(len(tasks)):
                out = clf_out[j+1][i].data
                a, b = out.topk(max_results[j])
                b = b.numpy()
                confidences = softmax(a.numpy())
                tasks_out.append([(self._task_labels[tasks[j]][b[k]], confidences[k]) for k in range(len(b))])

            if output_embeddings:
                res.append([clf_out[0][i].data.numpy()] + tasks_out)
            else:
                res.append(tasks_out)

        return res

    def _load_clf_net(self):
        base = self._load_basenet()

        tops = []
        for task in self.tasks:
            top = torch.nn.Linear(2048, self._task_class_count[task])
            model_name = 'fashion_%s_clf_%s' % (self._task_names[task], 'cuda' if self.use_cuda else 'nocuda')
            top.load_state_dict(load_url(model_urls[model_name],
                                         self.models_path,
                                         use_cuda=self.use_cuda))
            tops.append(top)

        clf = MultiClassifierNet(base, tops, output_embeddings=True)

        if self.use_cuda:
            clf = torch.nn.DataParallel(clf).cuda()

        # not training
        clf.eval()

        return clf

    def _load_basenet(self):
        base = Inception3Base(transform_input=True)

        if self.use_cuda:
            base = torch.nn.DataParallel(base).cuda()

        model_name = 'fashion_inceptionv3_notop_%s' % ('cuda' if self.use_cuda else 'nocuda')
        base.load_state_dict(load_url(model_urls[model_name],
                                      self.models_path,
                                      use_cuda=self.use_cuda))

        return base


class MultiClassifierNet(nn.Module):
    def __init__(self, base, tops, output_embeddings=False):
        super(MultiClassifierNet, self).__init__()
        self.output_embeddings = output_embeddings
        self.base = base
        self.tops = tops

    def forward(self, x, tasks=[]):
        emb = self.base(x)
        out = [self.tops[i.value](emb) for i in tasks]
        if self.output_embeddings:
            return [emb] + out
        return out
