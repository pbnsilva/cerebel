import os
import io
import shutil
import requests
import api.annotation_pb2 as pb
from cerebel.lang.matcher import (VocabEntityMatcher,
                                  PriceRangeMatcher,
                                  ColorMatcher,
                                  BrandMatcher)


class TextAnnotator:
    GS_LANG = 'https://storage.googleapis.com/data.cerebel.io/models/lang'
    VERSIONS_FILE = GS_LANG + '/VERSIONS'

    def __init__(self, models_path, ontology, logger):
        self.models_path = models_path
        self.logger = logger
        self.logger.info('TextAnnotator - loading models...')
        self._fetch_models()
        self.entity_matcher = VocabEntityMatcher(os.path.join(models_path, 'vocab.dat'))
        self.color_matcher = ColorMatcher(os.path.join(models_path, 'colors.dat'))
        self.brand_matcher = BrandMatcher(os.path.join(models_path, 'brands.dat'))
        self.price_range_matcher = PriceRangeMatcher()
        self.ontology = ontology
        self.logger.info('TextAnnotator - done loading models')

    def annotate(self, request):
        entity_annotations = []
        price_range_annotation = None
        for feature in request.features:
            if feature.type == pb.TextFeature.Type.Value('ENTITY_PREDICTION'):
                entity_annotations = self._get_entity_annotations(request)
                entity_annotations += self._get_color_annotations(request)
                entity_annotations += self._get_brand_annotations(request)

                # merge overlapping entities of different types
                entity_annotations = self._merge_entity_annotations(entity_annotations)
            elif feature.type == pb.TextFeature.Type.Value('PRICE_RANGE_DETECTION'):
                price_range_annotation = self._get_price_range_annotation(request)

        response = pb.AnnotateTextResponse(
            entity_annotations=entity_annotations,
            price_range_annotation=price_range_annotation)

        return response

    def annotate_bulk(self, requests):
        # TODO actual bulk
        return [self.annotate(request) for request in requests]

    def _fetch_models(self):
        # queries gstorage 'current' file for latest model versions
        # downloads, if needed
        req = requests.get(self.VERSIONS_FILE)
        if req.status_code != 200:
            raise Exception('there was an error downloading lang versions file: ' + req.text)
        data = req.json()
        for mname in data:
            fpath = os.path.join(self.models_path, '%s.dat' % mname)
            if not os.path.exists(self.models_path):
                os.makedirs(self.models_path)

            mpath = self.GS_LANG + '/' + data[mname]
            self.logger.info('Downloading model "%s"' % mpath)
            r = requests.get(mpath, stream=True)
            with io.open(fpath, mode='wb') as f:
                shutil.copyfileobj(r.raw, f)

    def _merge_entity_annotations(self, annotations):
        result = []
        annotations = sorted(annotations, key=lambda an: an.start)
        last_start, last_end = -1, -1
        for an in annotations:
            start, end = an.start, an.end
            if end > last_end:
                if start == last_start:
                    result.pop()
                    result.append(an)
                elif start > last_start:
                    result.append(an)
            last_start, last_end = start, end
        return result

    def _get_entity_annotations(self, request):
        entity_annotations = []
        matches = self.entity_matcher.match(request.text)
        for eid, start, end, original in matches:
            entity = self.ontology.get_entity(eid)
            if not entity:
                self.logger.error('TextAnnotator - entity not found: "%s"' % eid)
                continue
            entity_annotations.append(pb.EntityAnnotation(id=eid,
                                                          cls=self._get_entity_root_class_label(entity).lower().replace(' ', '_'),
                                                          label=entity.label.lower(),
                                                          start=start,
                                                          end=end,
                                                          original=original,
                                                          relations=[]))
        return entity_annotations

    def _get_color_annotations(self, request):
        color_annotations = []
        matches = self.color_matcher.match(request.text)
        for text, start, end in matches:
            color_annotations.append(pb.EntityAnnotation(cls='color',
                                                         label=text,
                                                         start=start,
                                                         end=end,
                                                         original=text))
        return color_annotations

    def _get_brand_annotations(self, request):
        brand_annotations = []
        matches = self.brand_matcher.match(request.text)
        for label, original, start, end in matches:
            brand_annotations.append(pb.EntityAnnotation(cls='brand',
                                                         label=label,
                                                         start=start,
                                                         end=end,
                                                         original=original))
        return brand_annotations

    def _get_entity_root_class_label(self, entity):
        root_class = entity
        while root_class.parent is not None:
            root_class = root_class.parent
        return root_class.label

    def _get_price_range_annotation(self, request):
        ann = self.price_range_matcher.match(request.text)
        if not ann:
            return
        range_annotations = []
        for op, val in ann[1]:
            range_annotations.append(pb.RangeAnnotation(operator=pb.RangeAnnotation.RangeOperator.Value(op.upper()),
                                                        value=val))
        return pb.PriceRangeAnnotation(currency=ann[0], range_annotations=range_annotations)
