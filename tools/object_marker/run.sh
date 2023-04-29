#!/bin/sh
CMD="npm start";
FLAGS="";

if [ "$(uname)" == "Darwin" ]; then
  FLAGS+=" EVENT_NOKQUEUE=1 ";
fi

if [ "$1" == "--nodemon" ]; then
  eval "nodemon -x $FLAGS $CMD";
else
  eval "$FLAGS $CMD";
fi
