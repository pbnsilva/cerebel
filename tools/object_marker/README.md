## Object Marker

A tool to easily annotate objects in a image following the PASCAL VOC format.

Shamelessly stolen from: [https://github.com/fancy967/ObjectMarker](https://github.com/fancy967/ObjectMarker).

Modified to work with Cerebel's dataset directory structure and classes.

![Screenshot](object_marker_grab.jpeg?raw=true "Screenshot")

### Install
```
npm install
```

### Run
```
./run.sh
```
And point it to the base dataset directory, e.g. `/Users/pedro/data/cerebel-fashion-voc`.
Expects a directory with the following structure:
```
cerebel-fashion-voc\
  Annotations\
  ImageSets\
  JPEGImages\
```

To automatically reload on code change, install `nodemon`:
```
npm install -g nodemon
```
and run:
```
./run.sh --nodemon
```
