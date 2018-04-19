# AudioStreamerScrobbler

## Warning: ALPHA version

This program is not ready for prime time yet, it's under heavy development. At this time it can only monitor 1 chosen BluOS device. In a future version, a single instance should be able to monitor all players of all supported audiostreamer standards.

Note that the program uses the undocumented LSDP protocol to detect BluOs players that are powered on. I could only test it with my BluOS player, which is the built-in streamer (internal BluOS 2 MDC upgrade card) in my NAD C368 amplifier. Therefore I don't know yet whether it will work on other players, like BlueSound's more popular wi-fi speakers, or their Node range of products.

## Description  

AudioStreamerScrobbler is an application that monitors hardware audiostreamers (currently only BluOS devices, but Yamaha MusicCast support is planned for the near future) and scrobbles played tracks to one or more of the following scrobbler services:

* Last FM (https://last.fm)
* ListenBrainz (https://listenbrainz.org/)
* Libre FM (https://libre.fm)
* A GNU FM instance (https://www.gnu.org/software/gnufm/)

The program is intended to be used 24/7 on Raspberry pi-alike devices, although the program has not been tested on those small computers yet. Hopefully BluOS and Yamaha will one day implement native Last FM support in their streaming platforms, but until that time you'll be able to use this workaround. As it is unlikely that those  companies will offer compatibility with the alternative scrobbler services, this program could still be useful, even when official Last FM support will be available.

AudioStreamerScrobbler was written in [Eclipse Golo, a lesser known dynamic language that runs on the Java Virtual Machine (JVM)](http://golo-lang.org). It was a design goal to write as much code in Golo as possible and not to use additional Java dependencies (unless very unpractical). We'll see how that wil turn out on the longer run. I had to write some code in Java to work around omissions in the Golo run-time library, but luckily Gradle takes care of those complexities when building the project. Although I'm personally not the biggest fan of dynamic languages, I really started to like Golo while I was developing this program. In my opinion it's a nice, small and clean language, with a surprisingly powerful run-time library.

## Requirements

AudioStreamerScrobbler is a project powered by the Java Virtual Machine. To run it, the Java Runtime Environment (JRE) version 8 is required.

Since this is a alpha pre-release, the program must be compiled before it can be used. To compile the program, both the Java Developers Kit (JDK) version 8 and the Gradle build tool (https://gradle.org) are required. Gradle will download the required dependencies, compile the project and build a stand-alone JAR file that can be used to run the program. To compile, issue the following command in the project's root directory (the directory containing the "build.gradle" file):

    gradle build

In the build/libs subdirectory, you'll find a audiostreamerscrobbler-0.1.0-SNAPSHOT-all.jar file that you can run with the `java -jar audiostreamerscrobbler-0.1.0-SNAPSHOT-all.jar` command. But be advised that you'll need to do some manual configuration first. This will be explained in the next section.

## Installation

After compiling the project, copy the builds/libs/audiostreamerscrobbler-0.1.0-SNAPSHOT-all.jar file to a directory that is convenient for you. In the same directory, create a config.json file that looks like this:

    {
        "player": {
            "type": "bluos",
            "name": "Living Room C368"
        },
        "scrobblers": {
            "lastfm": {
                "enabled": true,
                "apiKey": "",
                "apiSecret": "",
                "sessionKey": ""
            },
            "listenbrainz" {
                "enabled": true,
                "userToken": ""
            },
            "librefm": {
                "enabled": true,
                "sessionKey": ""
            },
            "gnufm": {
                "enabled": true,
                "nixtapeUrl": "192.168.178.109/nixtape",
                "sessionKey": ""
            }
        },
        "settings": {
            "errorHandling": {
                "maxSongs": 100,
                "retryIntervalMinutes": 30
            }
        }
    }

This format will change once multiple players and more type of players are supported. I'll make sure this README.md file will always contain an up-to-date example.
	
### Setting up the player

At this time, the program can monitor exactly one BluOS player. It should also be compatible with the new third party BlueOS powered devices that have appeared on the market, but this has not been tested yet. Enter the name of your device in the config.json's "name" field in the "player" section. 

The player name must match your BluOS device name exactly. Note that the name is CaSe SeNsItIvE. My BluOS device is called "Living Room C368" (when translated to English), so that's what's in my config.json file.

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

#### ListenBrainz

[ListenBrainz](https://listenbrainz.org) is a new service, operated by the [MetaBrainz Foundation](https://metabrainz.org). It is a new service and at the time of writing still in beta.

To use this program with MusicBrainz, first get yourself an account. In your user profile, you'll find your unique user token. Copy and paste this and place this in the "userToken" field of the "listenbrainz" entry in the config.json file. Don't forget to set the "enabled" field to the "true" value.

ListenBrainz support has only been added very recently and some work needs to be done on the handling of errors, so at this time Listens can get lost when problems occur.
	
#### Libre FM

[Libre FM](https://libre.fm) is a free alternative for Last FM. It is basically a rebranded GNU FM (see below), with a nicer UI theme, run as a cloud service by the  developers of GNU FM. It was started in 2009, but it still does not offer a recommendation engine. Therefore Libre FM is, at least for now, most useful if you primarily want to archive your listening habits. The maintainers of Libre FM promise not to sell your user data, very much unlike Last FM.

If you want to use AudioStreamerScrobbler with Libre FM, make sure that the "librefm" entry in the config.json file has the "enabled" key set to value "true". Then run the following command on a terminal that has access to a GUI desktop browser:

    java -jar audiostreamerscrobbler-0.1.0-SNAPSHOT-all.jar --authorize librefm

See the Last FM entry for more detailed instructions on the authorization process, the process is very much the same with Libre FM. Note that at the time of writing, AudioStreamerScrobbler client is not known by Libe FM, so it will show as an unknown client/API keys for the time being. After authorizing, just copy and paste it and place the returned session key in the "sessionKey" value in the config.json's "librefm" entry.

#### GNU FM

Unlike the others, [GNU FM](https://www.gnu.org/software/gnufm/) is not a cloud service. Instead, it is a web application that can be downloaded and deployed on any server, even on a local machine. It is very similar to Libre FM, but they differ quite a bit in the user-interface department. 

The beauty of GNU FM is that it is open-source. You can take it and adjust it fully to your needs (some PHP, HTML, JavaScript and database knowledge will be needed). If you make changes that you'll contribute back to the GNU FM project, you will help the Libre FM project as well, as they are based on the same codebase.

If you are concerned that cloud services like Last FM, Libre FM and ListenBrainz will disappear without warning one day, it could be worthwile to run and maintain a GNU FM instance yourself. Of course the social aspect of scrobbling is lost then, unless you share your GNU FM instance with other people. It should be noted, though, that Libre FM can be linked to GNU FM instances that are accessable from the web. 

If you want to use AudioStreamerScrobbler with GNU FM, make sure that the "gnufm" entry in the config.json file has the "enabled" key set to value "true". 

Also, you'll need to enter the URL to GNU FM. At this time, GNU FM consists of two submodules: "NixTape" (this module consists of the user interface and the AudioScrobbler 2.0 API protocol implementation) and "Gnukebox" (this module implements the older AudioScrobbler 1.x API protocol, which AudioStreamerScrobbler does not use at all). in the "nixtapeUrl" entry in the config.json file, you should enter the URL that you'll use to access your GNU FM application from your browser. On my machine, I've installed GNU FM on a virtual machine and entered te following url: "192.168.178.109/nixtape", still, your IP address wil most likely be different.

After all this, run the following command on a terminal that has access to a GUI desktop internet browser:

    java -jar audiostreamerscrobbler-0.1.0-SNAPSHOT-all.jar --authorize gnufm

See the Last FM entry for more detailed instructions on the authorization process, the process is very much the same with GNU FM. Note that at the time of writing, AudioStreamerScrobbler client is not known by GNU FM, so it will show as an unknown client/API keys for the time being. After authorizing, just copy and paste it and place the returned session key in the "sessionKey" value in the config.json's "gnufm" entry.
	
### Configuring scrobble errors parameters

As this program was created for Raspberry pi-alike devices, it currently can only register songs that could not be scrobbled in volatile memory (storing them on the filesystem will damage SD cards on the long run). This means that the program will not persist them and when quitting the application before it had a chance to scrobble the songs, those scrobbles will be lost forever.

You can choose how many songs it can store per scrobbler by setting the desired amount in the "maxSongs" entry. You can also configure the interval on which it will try to scrobble those songs by setting the "retryIntervalMinutes" entry in the confgiuration file. This interval is always specified in minutes.

Songs that could not be scrobbled for 14 days in a row are silently dropped, as required by Last FM.

## Plans

Above on my to-do list is perfecting the ListenBrainz support. Then I'd want to add Yamaha MusicCast support (as I use both BluOS and MusicCast devices in my home). Then the time will be right to make the program multi-threaded, so that it will be able to monitor multiple players (of multiple types) at once. Ideally I'd like to add HEOS by Denon support as well.

Please let me know if there's any demand for support of other types/brands.

On the longer term I'd like to add more advanced grouping possibilities, so that different group of devices can scrobble to different accounts on different services. Also, I'd like to add a GUI mode to configure the program in a more user friendly way. Time will tell if this application will ever get that advanced.

Right now I mostly concentrate on features that I'll use myself, but if there's demand I'd love to switch priorities.