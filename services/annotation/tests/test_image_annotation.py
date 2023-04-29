import sys
sys.path.append('../api')
import annotation_pb2 as pb
import annotation_pb2_grpc
import grpc
from io import BytesIO
from PIL import Image
import sys
import os


def run():
    if len(sys.argv) < 3:
        print('Missing path to image file and feature types.\nExample: python test_image_annotation.py image.jpg FEATURE_VECTOR CATEGORY_PREDICTION\n')
        sys.exit(2)

    channel = grpc.insecure_channel('localhost:9092')
    stub = annotation_pb2_grpc.AnnotatorStub(channel)

    requests = []
    for path in sys.argv[1].split(','):
        image_req = None
        if os.path.isfile(path):
            img = Image.open(path)
            bytes_ar = BytesIO()
            img.save(bytes_ar, format='PNG')
            bytes_ar = bytes_ar.getvalue()
            image_req = pb.Image(content=bytes_ar)
        else:
            image_req = pb.Image(source=pb.ImageSource(image_url=path))
        requests.append(pb.AnnotateImageRequest(image=image_req,
                                                features=[pb.ImageFeature(type=pb.ImageFeature.Type.Value(name), max_results=5) for name in sys.argv[2:]]))

    annotations = stub.BatchAnnotateImages(pb.BatchAnnotateImagesRequest(requests=requests))

    print(annotations)


if __name__ == '__main__':
    run()
