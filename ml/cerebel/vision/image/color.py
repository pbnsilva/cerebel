import os
import requests
import numpy as np
from sklearn.externals import joblib
import skimage.filters as skf
import skimage.color as skc
import skimage.morphology as skm
from skimage.filters import gaussian
from skimage.transform import resize
from skimage.measure import label
from skimage.color import rgb2hsv
from sklearn.cluster import KMeans


class ColorDetector:
    # Normalized identity (BGR gray) vector.
    _GRAY_UNIT = np.array([1, 1, 1]) / np.linalg.norm(np.array([1, 1, 1]))

    # Coefficients for BGR -> luminance.
    _GRAY_COEFF = np.array([0.114, 0.587, 0.299], np.float32)

    do_hard_monochrome = True
    skin_k = skm.disk(1, np.bool)
    skin_lo = np.array([0, 0.19, 0.31], np.float64)
    skin_up = np.array([0.1, 1., 1.], np.float64)
    kmeans_args = {
        'max_iter': 50,
        'tol': 1.0,
    }

    def __init__(self, models_path):
        self.models_path = models_path
        self._kmeans_clf = self._load_kmeans_clf()
        self._names = self._load_names()

    def extract(self, image):
        im = np.array(image)[:, :, :3]

        resized = self._get_crop(im)
        back_mask = self._get_back_mask(resized)
        skin_mask = self._get_skin_mask(resized)
        mask = back_mask | skin_mask
        k, labels, clusters_centers = self._get_cluster(resized[~mask])
        # centers = select(k, labels, clusters_centers)
        colors = [self._get_name(c, self._kmeans_clf, self._names)[0] for c in clusters_centers]

        return colors, clusters_centers

    def _load_kmeans_clf(self):
        fpath = os.path.join(self.models_path, 'color_kmeans_clf.pkl')
        req = requests.get('https://storage.googleapis.com/data.cerebel.io/models/vision/color_kmeans_clf.pkl')
        with open(fpath, 'wb') as f:
            f.write(req.content)
        return joblib.load(fpath)

    def _load_names(self):
        fpath = os.path.join(self.models_path, 'color_names.npz')
        if not os.path.isfile(fpath):
            req = requests.get('https://storage.googleapis.com/data.cerebel.io/models/vision/color_names.npz')
            with open(fpath, 'wb') as f:
                f.write(req.content)
        labels = np.load(fpath)['labels']
        return np.unique(labels, return_inverse=True)[0]

    def _get_crop(self, img):
        """Returns `img` cropped and resized."""
        return self._crop_resize(self._crop_crop(img))

    def _get_back_mask(self, img):
        f = self._back_floodfill(img)
        g = self._back_global(img)
        m = f | g

        if np.count_nonzero(m) < 0.90 * m.size:
            return m

        ng = np.count_nonzero(g)
        nf = np.count_nonzero(f)

        if ng < 0.90 * g.size and nf < 0.90 * f.size:
            return g if ng > nf else f

        if ng < 0.90 * g.size:
            return g

        if nf < 0.90 * f.size:
            return f

        return np.zeros_like(m)

    def _get_skin_mask(self, img):
        img = rgb2hsv(img)

        return self._skin_range_mask(img)

    def _get_cluster(self, img):
        return self._cluster_jump(img)

    def _get_name(self, sample, color_name_clf, color_names):
        """Return the color names for `sample`"""
        labels = []
        sample = sample * 255

        if self.do_hard_monochrome:
            labels = self._hard_monochrome(sample)
            if labels:
                return labels

        sample = sample.reshape((1, -1))
        labels += [color_names[i] for i in color_name_clf.predict(sample)]
        return labels

    def _crop_resize(self, img):
        src_h, src_w = img.shape[:2]
        dst_h = 100
        dst_w = int((dst_h / src_h) * src_w)
        return resize(img, (dst_h, dst_w), mode='reflect')

    def _crop_crop(self, img):
        src_h, src_w = img.shape[:2]
        c = 0.9
        dst_h, dst_w = int(src_h * c), int(src_w * c)
        rm_h, rm_w = (src_h - dst_h) // 2, (src_w - dst_w) // 2
        return img[rm_h:rm_h + dst_h, rm_w:rm_w + dst_w].copy()

    def _back_floodfill(self, img):
        back = self._back_scharr(img)
        # Binary thresholding.
        back = back > 0.05

        # Thin all edges to be 1-pixel wide.
        back = skm.skeletonize(back)

        # Edges are not detected on the borders, make artificial ones.
        back[0, :] = back[-1, :] = True
        back[:, 0] = back[:, -1] = True

        # Label adjacent pixels of the same color.
        labels = label(back, background=-1, connectivity=1)

        # Count as background all pixels labeled like one of the corners.
        corners = [(1, 1), (-2, 1), (1, -2), (-2, -2)]
        for l in (labels[i, j] for i, j in corners):
            back[labels == l] = True

        # Remove remaining inner edges.
        return skm.opening(back)

    def _back_global(self, img):
        h, w = img.shape[:2]
        mask = np.zeros((h, w), dtype=np.bool)
        max_distance = 5

        img = skc.rgb2lab(img)

        # Compute euclidean distance of each corner against all other pixels.
        corners = [(0, 0), (-1, 0), (0, -1), (-1, -1)]
        for color in (img[i, j] for i, j in corners):
            norm = np.sqrt(np.sum(np.square(img - color), 2))
            # Add to the mask pixels close to one of the corners.
            mask |= norm < max_distance

        return mask

    def _back_scharr(self, img):
        # Invert the image to ease edge detection.
        img = 1. - img
        grey = skc.rgb2grey(img)
        return skf.scharr(grey)

    def _skin_range_mask(self, img):
        mask = np.all((img >= self.skin_lo) & (img <= self.skin_up), axis=2)

        # Smooth the mask.
        skm.binary_opening(mask, selem=self.skin_k, out=mask)
        return gaussian(mask, 0.8, multichannel=True) != 0

    def _cluster_jump(self, img):
        npixels = img.size

        best = None
        prev_distorsion = 0
        largest_diff = float('-inf')

        for k in range(2, 7):
            compact, labels, centers = self._cluster_kmeans(img, k)
            distorsion = self._square_distorsion(npixels, compact, 1.5)
            diff = prev_distorsion - distorsion
            prev_distorsion = distorsion

            if diff > largest_diff:
                largest_diff = diff
                best = k, labels, centers

        return best

    def _hard_monochrome(self, sample):
        """
        Return the monochrome colors corresponding to `sample`, if any.
        A boolean is also returned, specifying whether or not the saturation is
        sufficient for non monochrome colors.
        """
        gray_proj = np.inner(sample, self._GRAY_UNIT) * self._GRAY_UNIT
        gray_dist = np.linalg.norm(sample - gray_proj)

        if gray_dist > 15:
            return []

        colors = []
        luminance = np.sum(sample * self._GRAY_COEFF)
        if luminance > 45 and luminance < 170:
            colors.append('gray')
        if luminance <= 50:
            colors.append('black')
        if luminance >= 170:
            colors.append('white')

        return colors

    def _cluster_kmeans(self, img, k):
        kmeans = KMeans(n_clusters=k, **self.kmeans_args)
        kmeans.fit(img)
        return kmeans.inertia_, kmeans.labels_, kmeans.cluster_centers_

    def _square_distorsion(self, npixels, compact, y):
        return pow(compact / npixels, -y)
