import os
import logging
import sys
sys.path.append('api/')
from api.grpc_service import AnnotatorGRPCService


if __name__ == '__main__':
    # TODO wrap configurations
    grpc_port = os.getenv('GRPC_PORT', 9092)
    data_path = os.getenv('DATA_PATH', '/data')

    logger = logging.getLogger('annotation_service')
    logger.setLevel(logging.INFO)
    ch = logging.StreamHandler()
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    ch.setFormatter(formatter)
    logger.addHandler(ch)

    grpc_service = AnnotatorGRPCService(logger, port=grpc_port, data_path=data_path)
    grpc_service.run()
