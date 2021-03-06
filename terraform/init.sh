#!/bin/bash

if [ ! -d ~/.tfenv ] ; then
    git clone https://github.com/tfutils/tfenv.git ~/.tfenv
    echo 'PATH=~/.tfenv/bin:$PATH' >> ~/.bash_profile
    PATH=~/.tfenv/bin:$PATH
fi

sudo yum -y install unzip

tfenv install
