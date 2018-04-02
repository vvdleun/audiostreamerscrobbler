call gradle clean build
cd build\libs
copy ..\..\config.json .
java -jar audiostreamerscrobbler-0.1.0-SNAPSHOT-all.jar --authorize gnufm
cd ..\..