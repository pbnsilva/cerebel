import torch.nn as nn
import torchvision.models as models


def vgg16(num_classes, pretrained=False):
    # load base model
    model = models.vgg16(pretrained=False)

    # change classifier
    model.classifier = nn.Sequential(
        nn.Dropout(),
        nn.Linear(25088, 4096),
        nn.ReLU(inplace=True),
        nn.Dropout(),
        nn.Linear(4096, 4096),
        nn.ReLU(inplace=True),
        nn.Linear(4096, num_classes),
    )

    return model
