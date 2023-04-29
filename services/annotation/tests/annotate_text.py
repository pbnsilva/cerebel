import sys
sys.path.append('../api')
import annotation_pb2 as pb
import annotation_pb2_grpc
import grpc
import sys


def run():
    if len(sys.argv) < 3:
        print('Missing text file and feature types.\nExample: python annotate_text.py "my text" ENTITY_PREDICTION\n')
        sys.exit(2)

    channel = grpc.insecure_channel('localhost:9092')
    stub = annotation_pb2_grpc.AnnotatorStub(channel)

    doc = sys.argv[1]

    requests = [
        pb.AnnotateTextRequest(text=doc,
                               features=[pb.TextFeature(type=pb.TextFeature.Type.Value(name), max_results=5) for name in sys.argv[2:]]),
    ]

    annotations = stub.BatchAnnotateTexts(pb.BatchAnnotateTextsRequest(requests=requests))

    print('"%s"' % doc)
    print(annotations)


if __name__ == '__main__':
    run()
