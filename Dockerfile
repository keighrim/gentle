FROM ubuntu:18.04

RUN DEBIAN_FRONTEND=noninteractive && \
	apt-get update && \
	apt-get install -y \
		gcc g++ gfortran \
		libc++-dev \
		libstdc++-6-dev zlib1g-dev \
		automake autoconf libtool \
		git subversion \
		libatlas3-base \
		nvidia-cuda-dev \
		ffmpeg \
		python3 python3-dev python3-pip \
		python python-dev python-pip \
		wget unzip && \
	apt-get clean

ADD ext /gentle/ext
RUN git clone https://github.com/kaldi-asr/kaldi /gentle/ext/kaldi
WORKDIR /gentle/ext/kaldi
RUN git checkout 7ffc9ddeb3c8436e16aece88364462c89672a183

ENV MAKEFLAGS=' -j8' 
WORKDIR /gentle/ext

# Prepare Kaldi
WORKDIR /gentle/ext/kaldi/tools
RUN make 
RUN ./extras/install_openblas.sh
WORKDIR /gentle/ext/kaldi/src
RUN ./configure --static --static-math=yes --static-fst=yes --use-cuda=no --openblas-root=../tools/OpenBLAS/install
RUN make depend

# build graph binaries that's actually used
WORKDIR /gentle/ext
RUN make depend && make 

# removed build residue
RUN rm -rf kaldi *o

ADD . /gentle
WORKDIR /gentle
RUN python3 setup.py develop
RUN ./install_models.sh

EXPOSE 8765

VOLUME /gentle/webdata

CMD python3 serve.py
