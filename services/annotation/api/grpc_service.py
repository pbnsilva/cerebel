import io
import requests
import shutil
import time
import grpc
import os
import api.annotation_pb2 as pb
from concurrent import futures
from cerebel.meta import Ontology
from image import ImageAnnotator
from text import TextAnnotator


class AnnotatorGRPCService(pb.AnnotatorServicer):
    GS_DATA = 'https://storage.googleapis.com/data.cerebel.io'

    def __init__(self, logger, port=9092, data_path='/data'):
        self.logger = logger
        self.port = int(port)

        self._create_dirs(data_path)

        ontology = self._fetch_ontology(data_path)

        self.image_annotator = ImageAnnotator(os.path.join(data_path, 'vision'), ontology, logger)
        self.text_annotator = TextAnnotator(os.path.join(data_path, 'models', 'lang'), ontology, logger)

    def BatchAnnotateImages(self, request, context):
        self.logger.info('Received image annotation batch with %d requests' % len(request.requests))
        responses = self.image_annotator.annotate_bulk(request.requests)
        return pb.BatchAnnotateImagesResponse(responses=responses)

    def BatchAnnotateTexts(self, request, context):
        self.logger.info('Received text annotation batch with %d requests' % len(request.requests))
        responses = self.text_annotator.annotate_bulk(request.requests)
        return pb.BatchAnnotateTextsResponse(responses=responses)

    def _create_dirs(self, data_path):
        meta_path = os.path.join(data_path, 'metadata')
        if not os.path.exists(meta_path):
            os.makedirs(meta_path)

        vision_path = os.path.join(data_path, 'vision')
        if not os.path.exists(vision_path):
            os.makedirs(vision_path)

        lang_path = os.path.join(data_path, 'lang')
        if not os.path.exists(lang_path):
            os.makedirs(lang_path)

    def _fetch_ontology(self, data_path):
        fpath = os.path.join(data_path, 'metadata', 'ontology.json')
        if os.path.exists(fpath):
            os.remove(fpath)
        r = requests.get(self.GS_DATA + '/metadata/ontology.json', stream=True, headers={'Cache-Control': 'no-cache'})
        with io.open(fpath, mode='wb') as f:
            shutil.copyfileobj(r.raw, f)
        return Ontology(fpath)

    def run(self):
        server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
        pb.add_AnnotatorServicer_to_server(self, server)
        server.add_insecure_port('[::]:%d' % self.port)
        server.start()
        self.logger.info('Server started at port %d' % self.port)
        try:
            while True:
                time.sleep(60 * 60 * 24)
        except KeyboardInterrupt:
            server.stop(0)
