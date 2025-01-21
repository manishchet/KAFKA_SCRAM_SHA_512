#!/bin/bash
# Generates several self-signed keys <name>.cer, <name>.jks, and <name>.p12.
# Truststore is set with name truststore.jks and set password of password12345
# Usage: createKey.sh <user> <password>
#        createKey.sh somebody password123
# -ext "SAN=DNS:"

export NAME=$1
export IP1=$2
export PASSWORD=7ecETGlHjzs
export STORE_PASSWORD=7ecETGlHjzs

echo "Creating key for $NAME using password $PASSWORD"

keytool -genkey -alias $NAME -keyalg RSA -keysize 4096 -dname "CN=$NAME,OU=ABC,O=ABC,L=ABC,ST=ABC,C=IN" -ext "SAN=DNS:$NAME,IP:$IP1" -keypass $PASSWORD -keystore $NAME.jks -storepass $PASSWORD -validity 7200

keytool -export -keystore $NAME.jks -storepass $PASSWORD -alias $NAME -file $NAME.cer

keytool -import -trustcacerts -file $NAME.cer -alias $NAME -keystore truststore.jks -storepass $STORE_PASSWORD -noprompt

echo "Done creating key for $NAME"

keytool -list -keystore truststore.jks -storepass $STORE_PASSWORD -noprompt







-------------JKStoPEM--------------
/opt/jdk1.8.0_151/bin/keytool -exportcert -alias hostname1.com -keystore truststore.jks -storepass 7ecETGlHjzs -file hostname1.crt
/opt/jdk1.8.0_151/bin/keytool -exportcert -alias hostname2.com -keystore truststore.jks -storepass 7ecETGlHjzs -file hostname2.crt
/opt/jdk1.8.0_151/bin/keytool -exportcert -alias hostname3.com -keystore truststore.jks -storepass 7ecETGlHjzs -file hostname3.crt

openssl x509 -inform der -in hostname1.crt -out hostname1.pem
openssl x509 -inform der -in hostname2.crt -out hostname2.pem
openssl x509 -inform der -in hostname3.crt -out hostname3.pem

cat *.pem > truststore_combined.pem