from .generic import SquarespaceSpider


class CarleenSpider(SquarespaceSpider):
    name = 'Carleen'
    max_pages = 5
    collection_urls = [{"value": "http://www.carleen.us/all/?format=json", "gender": ["women"]}]
    label_finder_urls = ["https://www.thelabelfinder.com/vancouver/carleen/shops/CA/7109346/6173331", "https://www.thelabelfinder.com/austin/carleen/shops/US/7109346/4671654", "https://www.thelabelfinder.com/los-angeles/carleen/shops/US/7109346/5368361", "https://www.thelabelfinder.com/new-york/carleen/shops/US/7109346/5128581", "https://www.thelabelfinder.com/oakland/carleen/shops/US/7109346/5378538", "https://www.thelabelfinder.com/portland/carleen/shops/US/7109346/5746545"]

    def filter_product(self, product):
        if 'gift' in product['name'].lower():
            return False
        return True
