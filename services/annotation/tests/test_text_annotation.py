import sys
sys.path.append('../api')
import annotation_pb2 as pb
import annotation_pb2_grpc
import grpc
import sys
import os


def run():
    if len(sys.argv) < 3:
        print('Missing path to text file and feature types.\nExample: python test_text_annotation.py doc.txt ENTITY_PREDICTION\n')
        sys.exit(2)

    channel = grpc.insecure_channel('localhost:9092')
    stub = annotation_pb2_grpc.AnnotatorStub(channel)

    doc = None
    if os.path.isfile(sys.argv[1]):
        with open(sys.argv[1], 'r') as f:
            doc = f.read().strip()

    requests = [
        pb.AnnotateTextRequest(text=doc,
                               features=[pb.TextFeature(type=pb.TextFeature.Type.Value(name), max_results=5) for name in sys.argv[2:]]),
    ]

    annotations = stub.BatchAnnotateTexts(pb.BatchAnnotateTextsRequest(requests=requests))

    print('"%s"' % doc)
    print(annotations)


if __name__ == '__main__':
    run()
