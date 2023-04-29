import numpy as np
import torch
from cerebel.vision.data import BaseTransform
from cerebel.vision.models import load_ssd
from cerebel.vision.datasets import SSD_CATEGORY_CLASSES


class ObjectDetector:
    def __init__(self, models_path):
        self.models_path = models_path
        self._transform = BaseTransform(300, (104, 117, 123))
        self._model = load_ssd(models_path)
        self._model.eval()

    def predict(self, image, max_results, min_score=0.6):
        detections = []
        img_array = np.array(image)
        x = torch.from_numpy(self._transform(img_array)[0]).permute(2, 0, 1)
        x = torch.autograd.Variable(x.unsqueeze(0))
        y = self._model(x)
        y_data = y.data
        scale = torch.Tensor([img_array.shape[1], img_array.shape[0], img_array.shape[1], img_array.shape[0]])
        for i in range(y_data.size(1)):
            for j in range(y_data.size(2)):
                score = y_data[0, i, j, 0]
                if score < min_score:
                    continue
                label_name = SSD_CATEGORY_CLASSES[i-1]
                pt = (y_data[0, i, j, 1:]*scale).cpu().numpy()
                coords = (int(pt[0]), int(pt[1]), int(pt[2]), int(pt[3]))
                detections.append((label_name, score, coords))
        detections = sorted(detections, key=lambda v: -v[1])[:max_results]
        return detections
