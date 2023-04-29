import requests
from PIL import Image
from io import BytesIO
import api.annotation_pb2 as pb
from cerebel.vision.classify import MultiClassifier
from cerebel.vision.detect import ObjectDetector
# from cerebel.vision.image import ColorDetector


class ImageAnnotator:
    def __init__(self, models_path, ontology, logger):
        self.logger = logger
        self.logger.info('ImageAnnotator - loading models...')
        self.ontology = ontology
        self.multi_classifier = MultiClassifier(models_path,
                                                [MultiClassifier.Tasks.CATEGORY_PREDICTION,
                                                 MultiClassifier.Tasks.IS_FASHION_PREDICTION,
                                                 MultiClassifier.Tasks.HAS_FACE_PREDICTION,
                                                 MultiClassifier.Tasks.TEXTURE_PREDICTION])
        self.object_detector = ObjectDetector(models_path)
        # self.color_detector = ColorDetector(models_path)
        self.logger.info('ImageAnnotator - done loading models')

    def annotate_bulk(self, requests):
        responses = []
        images = [None] * len(requests)
        for i, request in enumerate(requests):
            image = self.load_image(request.image)
            if image:
                images[i] = image
        clf_results = self._get_clf_results(requests, images)
        for i, request in enumerate(requests):
            if not images[i]:
                responses.append(pb.AnnotateImageResponse(error=pb.Status(code=400, message="Error loading image")))
                continue
            feature_vector = None
            category_annotations = None
            item_annotations = None
            # color_annotations = None
            is_fashion_annotation = None
            texture_annotations = None
            has_face_annotation = None
            clf_result = clf_results.get(i)
            for feature in request.features:
                if feature.type == pb.ImageFeature.Type.Value('FEATURE_VECTOR'):
                    feature_vector = clf_result['feature_vector']
                elif feature.type == pb.ImageFeature.Type.Value('CATEGORY_PREDICTION'):
                    category_annotations = clf_result[MultiClassifier.Tasks.CATEGORY_PREDICTION]
                elif feature.type == pb.ImageFeature.Type.Value('IS_FASHION_PREDICTION'):
                    is_fashion_annotation = clf_result[MultiClassifier.Tasks.IS_FASHION_PREDICTION]
                elif feature.type == pb.ImageFeature.Type.Value('TEXTURE_PREDICTION'):
                    texture_annotations = clf_result[MultiClassifier.Tasks.TEXTURE_PREDICTION]
                elif feature.type == pb.ImageFeature.Type.Value('HAS_FACE_PREDICTION'):
                    has_face_annotation = clf_result[MultiClassifier.Tasks.HAS_FACE_PREDICTION]
                elif feature.type == pb.ImageFeature.Type.Value('ITEM_DETECTION'):
                    detections = self.object_detector.predict(image, feature.max_results, min_score=0.6)
                    item_annotations = [pb.ItemAnnotation(label=label,
                                                          bbox=pb.BoundingBox(x_min=bbox[0], y_min=bbox[1], x_max=bbox[2], y_max=bbox[3]),
                                                          confidence=conf) for label, conf, bbox in detections]
                # elif feature.type == pb.ImageFeature.Type.Value('COLOR_DETECTION'):
                #    colors, cluster_centers = self.color_detector.extract(images[i])
                #    color_annotations = [pb.ColorAnnotation(label=colors[i],
                #                                            center=cluster_centers[i]) for i in range(len(colors))]
            responses.append(pb.AnnotateImageResponse(
                feature_vector=feature_vector,
                category_annotations=category_annotations,
                item_annotations=item_annotations,
                # color_annotations=color_annotations,
                is_fashion_annotation=is_fashion_annotation,
                texture_annotations=texture_annotations,
                has_face_annotation=has_face_annotation))
        return responses

    def _get_clf_results(self, requests, images):
        res = {}
        input_images = []
        tasks_nb_results = {}
        for i, request in enumerate(requests):
            if not images[i]:
                continue
            input_images.append(images[i])
            has_clf_task = False
            for feature in request.features:
                if feature.type == pb.ImageFeature.Type.Value('FEATURE_VECTOR'):
                    has_clf_task = True
                elif feature.type == pb.ImageFeature.Type.Value('CATEGORY_PREDICTION'):
                    tasks_nb_results[MultiClassifier.Tasks.CATEGORY_PREDICTION] = feature.max_results
                    has_clf_task = True
                elif feature.type == pb.ImageFeature.Type.Value('IS_FASHION_PREDICTION'):
                    tasks_nb_results[MultiClassifier.Tasks.IS_FASHION_PREDICTION] = 2
                    has_clf_task = True
                elif feature.type == pb.ImageFeature.Type.Value('TEXTURE_PREDICTION'):
                    tasks_nb_results[MultiClassifier.Tasks.TEXTURE_PREDICTION] = feature.max_results
                    has_clf_task = True
                elif feature.type == pb.ImageFeature.Type.Value('HAS_FACE_PREDICTION'):
                    tasks_nb_results[MultiClassifier.Tasks.HAS_FACE_PREDICTION] = 2
                    has_clf_task = True
            if has_clf_task:
                res[i] = {}

        if len(input_images) == 0:
            return res

        result_ct = 0
        results = self.multi_classifier.predict_bulk(input_images, list(tasks_nb_results.keys()), list(tasks_nb_results.values()), output_embeddings=True)
        for i in range(len(requests)):
            if i not in res:
                continue
            result = results[result_ct]
            result_ct += 1
            res[i]['feature_vector'] = pb.ImageFeatureVector(vector=result[0])
            for j, task in enumerate(tasks_nb_results):
                if task == MultiClassifier.Tasks.CATEGORY_PREDICTION:
                    labels_confs = result[j+1]
                    res[i][MultiClassifier.Tasks.CATEGORY_PREDICTION] = [pb.CategoryAnnotation(label=self.ontology.get_entity(cls).label.lower(), confidence=conf) for cls, conf in labels_confs]
                elif task == MultiClassifier.Tasks.IS_FASHION_PREDICTION:
                    res[i][MultiClassifier.Tasks.IS_FASHION_PREDICTION] = pb.IsFashionAnnotation(label=result[j+1][0][0], confidence=result[j+1][0][1])
                elif task == MultiClassifier.Tasks.TEXTURE_PREDICTION:
                    labels_confs = result[j+1]
                    res[i][MultiClassifier.Tasks.TEXTURE_PREDICTION] = [pb.TextureAnnotation(label=cls, confidence=conf) for cls, conf in labels_confs]
                elif task == MultiClassifier.Tasks.HAS_FACE_PREDICTION:
                    res[i][MultiClassifier.Tasks.HAS_FACE_PREDICTION] = pb.HasFaceAnnotation(label=result[j+1][0][0], confidence=result[j+1][0][1])

        return res

    def annotate(self, request):
        image = self.load_image(request.image)
        if image is None:
            return pb.AnnotateImageResponse(error=pb.Status(code=400, message="Error loading image"))

        item_annotations = None
        color_annotations = None
        clf_tasks = []
        nb_results = []
        output_embeddings = False
        for feature in request.features:
            if feature.type == pb.ImageFeature.Type.Value('FEATURE_VECTOR'):
                output_embeddings = True
            elif feature.type == pb.ImageFeature.Type.Value('CATEGORY_PREDICTION'):
                clf_tasks.append(MultiClassifier.Tasks.CATEGORY_PREDICTION)
                nb_results.append(feature.max_results)
            elif feature.type == pb.ImageFeature.Type.Value('IS_FASHION_PREDICTION'):
                clf_tasks.append(MultiClassifier.Tasks.IS_FASHION_PREDICTION)
                nb_results.append(2)
            elif feature.type == pb.ImageFeature.Type.Value('TEXTURE_PREDICTION'):
                clf_tasks.append(MultiClassifier.Tasks.TEXTURE_PREDICTION)
                nb_results.append(feature.max_results)
            elif feature.type == pb.ImageFeature.Type.Value('HAS_FACE_PREDICTION'):
                clf_tasks.append(MultiClassifier.Tasks.HAS_FACE_PREDICTION)
                nb_results.append(2)
            elif feature.type == pb.ImageFeature.Type.Value('ITEM_DETECTION'):
                detections = self.object_detector.predict(image, feature.max_results, min_score=0.6)
                item_annotations = [pb.ItemAnnotation(label=label,
                                                      bbox=pb.BoundingBox(x_min=bbox[0], y_min=bbox[1], x_max=bbox[2], y_max=bbox[3]),
                                                      confidence=conf) for label, conf, bbox in detections]
            elif feature.type == pb.ImageFeature.Type.Value('COLOR_DETECTION'):
                colors, cluster_centers = self.color_detector.extract(image)
                color_annotations = [pb.ColorAnnotation(label=colors[i],
                                                        center=cluster_centers[i]) for i in range(len(colors))]

        feature_vector = None
        category_annotations = None
        is_fashion_annotation = None
        texture_annotations = None
        has_face_annotation = None
        if clf_tasks or output_embeddings:
            start_ind = 0
            results = self.multi_classifier.predict(image, clf_tasks, nb_results, output_embeddings=output_embeddings)
            if output_embeddings:
                feature_vector = pb.ImageFeatureVector(vector=results[0])
                start_ind = 1
            for i in range(start_ind, len(clf_tasks)):
                task = clf_tasks[i]
                labels_confs = results[i]
                if task == MultiClassifier.Tasks.CATEGORY_PREDICTION:
                    category_annotations = [pb.CategoryAnnotation(label=self.ontology.get_entity(cls).label.lower(), confidence=conf) for cls, conf in labels_confs]
                elif task == MultiClassifier.Tasks.IS_FASHION_PREDICTION:
                    cls, conf = list(labels_confs)[0]
                    is_fashion_annotation = pb.IsFashionAnnotation(label=cls, confidence=conf)
                elif task == MultiClassifier.Tasks.TEXTURE_PREDICTION:
                    texture_annotations = [pb.TextureAnnotation(label=cls, confidence=conf) for cls, conf in labels_confs]
                elif task == MultiClassifier.Tasks.HAS_FACE_PREDICTION:
                    cls, conf = list(labels_confs)[0]
                    has_face_annotation = pb.HasFaceAnnotation(label=cls, confidence=conf)

        response = pb.AnnotateImageResponse(
            feature_vector=feature_vector,
            category_annotations=category_annotations,
            item_annotations=item_annotations,
            color_annotations=color_annotations,
            is_fashion_annotation=is_fashion_annotation,
            texture_annotations=texture_annotations,
            has_face_annotation=has_face_annotation)

        return response

    def load_image(self, image):
        # content is preferred to image_url
        if image.content:
            return Image.open(BytesIO(image.content)).convert('RGB')
        if image.source:
            try:
                resp = requests.get(image.source.image_url)
                return Image.open(BytesIO(resp.content)).convert('RGB')
            except (requests.exceptions.RequestException, OSError) as e:
                self.logger.error('Error loading image from url "%s": %s' % (image.source.image_url, e))
