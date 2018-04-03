# AudioStreamerScrobbler

## Warning: ALPHA version

This program is not ready for prime time yet, it's under heavy development. At this time it can only monitor 1 chosen BlueSound device and the program crashes when a scrobbler service does not accept the HTTP request for whatever reason.

Note that the program uses the undocumented LSDP protocol to detect BlueSound players that are powered on. I could only test it with my BlueSound player, which is the built-in streamer (internal BlueOS 2 MDC upgrade card) in my (lovely!) NAD C368 amplifier. Therefore I don't know yet whether it will work on other players, like BlueSound's more popular wi-fi speakers, or their Node range of products.

## Description  

AudioStreamerScrobbler is an application that monitors hardware audiostreamers (currently only BlueSound devices, but Yamaha MusicCast support is planned for the near future) and scrobbles played tracks to one or more of the following scrobbler services:

* Last FM (https://last.fm)
* Libre FM (https://libre.fm)
* A GNU FM instance (https://www.gnu.org/software/gnufm/)

Support for ListenBrainz (https://listenbrainz.org) is planned as well.

The program is intended to be used 24/7 on Raspberry pi-alike devices, although the program has not been tested on those small computers yet. Hopefully BlueSound and Yamaha will one day implement native Last FM support in their streaming platforms, but until that time you'll be able to use this workaround. As it is unlikely that those  companies will offer compatibility with the alternative scrobbler services, this program could still be useful, even when official Last FM support will be available.

AudioStreamerScrobbler was written in Golo , [a rather obscure dynamic language that runs on the Java Virtual Machine (JVM)](http://golo-lang.org). It was a design goal to write as much code in Golo as possible and not to use additional Java dependencies. We'll see how that wil turn out on the longer run. I had to write some code in Java to work around omissions in the Golo run-time library, but luckily Gradle takes care of those complexities when building the project.

## Requirements

AudioStreamerScrobbler is a project powered by the Java Virtual Machine. To run it Java Runtime Environment (JRE) version 8 is required. To compile the program, Gradle build tool (https://gradle.org) is required as well. This will download the required dependencies, compile the project and build a stand-alone JAR file that can be used to run the program. To compile, issue the following command in the project's root directory (the directory containing the "build.gradle" file):

    gradle build

In the build/libs subdirectory, you'll find a audiostreamerscrobbler-0.1.0-SNAPSHOT-all.jar file that you can run with the `java -jar audiostreamerscrobbler-0.1.0-SNAPSHOT-all.jar` command. But be advised that you'll need to do some manual configuration first.

## Installation

Copy the audiostreamerscrobbler-0.1.0-SNAPSHOT-all.jar file to a directory that is convenient for you. In the same directory, create a config.json file that looks like this:

    {
        "player": {
            "type": "bluesound",
            "name": "Living Room C368"
        },
        "scrobblers": {
            "lastfm": {
                "enabled": true,
                "apiKey": "",
                "apiSecret": "",
                "sessionKey": ""
            },
            "librefm": {
                "enabled": true,
                "sessionKey": ""
            },
            "gnufm": {
                "enabled": true,
                "nixtapeUrl": "192.168.178.109/nixtape",
                "sessionKey": ""
            },
        }
    }

### Setting up the player

At this time, the program can monitor exactly one BlueSound player. It should also be compatible with the new third party BlueOS powered devices that have appeared on the market, but this has not been tested yet. Enter the name of your device in the config.json's "name" field in the "player" section. 

The player name must match your BlueSound device name exactly. Note that the name is CaSe SeNsItIvE. My BlueSound device is called "Living Room C368" (when translated to English), so that's what's in my config.json file.

### Setting up scrobbler services

For each scrobbler service, set the "enabled" field to "true" for the scrobbler services that you want to use. Make sure you'll set the others to "false", otherwise the application will probably crash. 

Coming up are instructions to authorize the application with each scrobbler service.

#### Last FM

[Last FM](https://last.fm) is the scrobbler service that started it all. In my opinion, its recommendation engine is still unbeatable.

To use this program with Last FM, first get yourself an API key and API secret at https://www.last.fm/api/account/create
You can keep the "Callback URL" empty, as it is not used by this desktop app. Note that Last FM's account page has been broken for a long time,
you won't be able to retrieve the API key/secret in your account screen, so if you lose your keys, you'll have to request a new pair.
	
Put the API key and secret in the correct fields in the config.json file, then run the following command on a machine that has a desktop GUI browser:

    java -jar audiostreamerscrobbler-0.1.0-SNAPSHOT-all.jar --authorize lastfm

This will start a browser. If you are not logged in to Last FM, you are asked to log in. After logging in, Last FM will ask you whether you want to authorize the application. If this is what you want, click Yes. Then open the console window and press Enter, to let the application know that you have authorized the application. It will then continue the authorization process. Finally, it will show the value for the session key. Copy and paste it and place it in the "sessionKey" value in the config.json's "lastfm" entry.
	
#### Libre FM

[Libre FM](https://libre.fm) is a free alternative for Last FM. It is basically a rebranded GNU FM (see below), with a nicer UI theme, run as a cloud service by the  developers of GNU FM. It was started in 2009, but it still does not offer a recommendation engine. Therefore Libre FM is, at least for now, most useful if you primarily want to archive your listening habits. The maintainers of Libre FM promise not to sell your user data, very much unlike Last FM.

If you want to use AudioStreamerScrobbler with Libre FM, make sure that the "librefm" entry in the config.json file has the "enabled" key set to value "true". Then run the following command on a terminal that has access to a GUI desktop browser:

    java -jar audiostreamerscrobbler-0.1.0-SNAPSHOT-all.jar --authorize librefm

This will start a browser. If you are not logged in to Libre FM, you are asked to log in. After logging in, Libre FM will ask you whether you want to authorize the application. If this is what you want, click Yes. Note that at the time of writing, AudioStreamerScrobbler is not known by Libe FM, so it will show as an unknown client for the time being. After this, open the console window that runs AudioStreamerScrobbler and press Enter, to let the application know that you have authorized the application. It will then continue the authorization process. Finally, it will show the value for the session key. Copy and paste it and place it in the "sessionKey" value in the config.json's "librefm" entry.

#### GNU FM

Unlike the others, [GNU FM](https://www.gnu.org/software/gnufm/) is not a cloud service. Instead, it is a web application that can be downloaded and deployed on any server, even on a local machine. It is very similar to Libre FM, but they differ quite a bit in the user-interface department. 

The beauty of GNU FM is that it is open-source. You can take it and adjust it fully to your needs (some PHP, HTML, JavaScript and database knowledge will be needed). If you make changes that you'll contribute back to the GNU FM project, you will help the Libre FM project as well, as they are based on the same codebase.

If you are concerned that cloud services like Last FM, Libre FM and ListenBrainz will disappear without warning one day, it could be worthwile to run and maintain a GNU FM instance yourself. Of course the social aspect of scrobbling is lost then, unless you share your GNU FM instance with other people. It should be noted, though, that Libre FM can be linked to GNU FM instances that are accessable from the web. 

If you want to use AudioStreamerScrobbler with GNU FM, make sure that the "gnufm" entry in the config.json file has the "enabled" key set to value "true". 

Also, you'll need to enter the URL to GNU FM. At this time, GNU FM consists of two submodules: "NixTape" (this module consists of the user interface and the AudioScrobbler 2.0 API protocol implementation) and "Gnukebox" (this module implements the older AudioScrobbler 1.x API protocol, which AudioStreamerScrobbler does not use at all). in the "nixtapeUrl" entry in the config.json file, you should enter the URL that you'll use to access your GNU FM application from your browser. On my machine, I've installed GNU FM on a virtual machine and entered te following url: "192.168.178.109/nixtape", still, your IP address wil most likely be different.

After all this, run the following command on a terminal that has access to a GUI desktop internet browser:

    java -jar audiostreamerscrobbler-0.1.0-SNAPSHOT-all.jar --authorize gnufm

This will start your internet browser. If you are not logged in to GNU FM, you are asked to log in. After logging in, GNU FM will ask you whether you want to authorize the application. If this is what you want, click Yes. Note that at the time of writing, AudioStreamerScrobbler is not known by GNU FM, so it will show as an unknown client for the time being. After this, open the console window and press Enter, to let the application know that you have authorized the application. It will then continue the authorization process. Finally, it will show the value for the session key. Copy and paste it and place it in the "sessionKey" value in the config.json's "librefm" entry.

#### ListenBrainz

Support will be coming soon, it is at the top of my priority list.

## Plans

First I want to make the application as stable as possible and add ListenBrainz support. Then I'd want to add Yamaha MusicCast support (as I use both BlueSound and MusicCast devices in my home). Then the time will be right to make the program multi-threaded, so that it will be able to monitor multiple players at once.

On the longer term I'd like to add advanced grouping possibilities, so that different group of devices can scrobble to different accounts on different services. Time will tell if this application will ever get that advanced.