import json


class Entity:
    def __init__(self, key=None, label=None, parent=None, children=None):
        self.key = key
        self.label = label
        self.parent = parent
        self.children = children


class Ontology:
    def __init__(self, file_path):
        self._graph = self._load_entities(file_path)

    def get_entity(self, key):
        return self._graph.get(key)

    def get_entities(self):
        return list(self._graph.values())

    def _load_entities(self, file_path):
        graph = {}
        data = json.load(open(file_path, 'r'))
        for key, val in data.items():
            entity = graph.setdefault(key, Entity(key=key, children=[]))
            entity.label = val['label']
            for subcat in val.get('subcategories', []):
                sub_entity = graph.setdefault(subcat, Entity(key=subcat, children=[]))
                entity.children.append(sub_entity)
                sub_entity.parent = entity
        return graph
