#!/bin/sh
#

# git clone -b umtprd-1.6.2 https://github.com/viveris/uMTP-Responder.git
git clone https://github.com/viveris/uMTP-Responder.git
cd uMTP-Responder
make -j 4
cp umtprd /root/bin/
