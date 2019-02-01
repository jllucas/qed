#!/bin/bash
set -x
set -e

function _readlink() { (
  # INFO: readlink does not exists on OSX ¯\_(ツ)_/¯
  cd $(dirname $1)
  echo $PWD/$(basename $1)
) }

pub=$(_readlink ./data)
tdir=$(mktemp -d /tmp/prometheus.XXX)

app_path=${pub}/prometheus

mkdir -p ${pub}

(
cd ${tdir}

if [ ! -f ${app_path} ]; then (
    version=2.7.0
    folder=prometheus-${version}.linux-amd64
    link=https://github.com/prometheus/prometheus/releases/download/v${version}/${folder}.tar.gz
    wget -qO- ${link} | tar xvz -C ./
    cp ${folder}/prometheus ${app_path}
) fi

)
 rm -rf ${tdir}