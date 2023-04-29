from abc import ABC, abstractmethod


class BaseMatcher(ABC):
    @abstractmethod
    def match(self, docs):
        pass
