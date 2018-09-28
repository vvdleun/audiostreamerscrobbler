# AudioStreamerScrobbler

## Status update: Seemingly almost ready for prime-time

Personally, I have been using this program for some months now, on a Raspberry pi 1 model B, that monitors my NAD C368's Bluesound add-on MDC card (BluOS) and Yamaha ISX-18D and WX-010 (MusicCast) players and sends my played songs simultaneously to my personal Last.FM, Libre.FM and ListenBrainz accounts. The program seems to recover from many common I/O problems, although there are some improvements needed in that area. Even more importantly, it looks like I've fixed all serious memory leaks that plagued the project previously.

While testing the program, I have added experimental Denon HEOS support. After this implementation has improved and tested for some weeks, and some additional improvements, I'll plan to do a version 1.0 release. I hope to add a desktop GUI configuration option, so end-users won't have to edit a JSON file by hand anymore, as well.

## Description  

AudioStreamerScrobbler is an application that monitors hardware audiostreamers and scrobbles played tracks to one or more of the personal audio tracking ("scrobbler") services.

Supported hardware audiostreamers are:

* Bluesound/BluOS-based players
* Yamaha MusicCast players

Support for HEOS players (Denon) is currently experimental. 

The following music tracking services are supported:

* Last FM (https://last.fm)
* ListenBrainz (https://listenbrainz.org/, or a local installation of ListenBrainz Server)
* Libre FM (https://libre.fm)
* A GNU FM instance (https://www.gnu.org/software/gnufm/)

The program is intended to be used 24/7 on Raspberry pi-alike devices. I have personally compiled and have been running it on a Raspberry pi 1 Model B for some time now.

AudioStreamerScrobbler was written in [Eclipse Golo, a lesser known dynamic language that runs on the Java Virtual Machine (JVM)](http://golo-lang.org). It was a design goal to write as much code in Golo as possible and not to use additional Java dependencies, unless very unpractical. We'll see how that wil turn out on the longer run. I had to write some code in Java to work around omissions in the Golo run-time library, but luckily Gradle takes care of those complexities when building the project. Although I'm personally not the biggest fan of dynamic languages, I really started to like Golo while I was developing this program. In my opinion it's a nice, small and clean language, with a surprisingly powerful run-time library.

## Requirements

AudioStreamerScrobbler is a project powered by the Java Virtual Machine (JVM). To run it, the Java Runtime Environment (JRE) version 8 is required. Although Golo is not yet compatible with Java 9 and higher, it seems to compile/run on Java 9 and 10, with some warnings. It remains to be seen whether Golo will be made compatible with newer Java versions. If not, a port to a different programming language is not ruled out.

Since this is a alpha pre-release, the program must be compiled before it can be used. To compile the program, both the Java Developers Kit (JDK) version 8 and the Gradle build tool (https://gradle.org) are required. Gradle will download the required dependencies, compile the project and build a stand-alone JAR file that can be used to run the program. To compile, issue the following command in the project's root directory (the directory containing the "build.gradle" file):

    gradle build

In the build/libs subdirectory, you'll find a audiostreamerscrobbler-0.1.0-SNAPSHOT-all.jar file that you can run with the `java -jar audiostreamerscrobbler-0.1.0-SNAPSHOT-all.jar` command. But be advised that you'll need to do some manual configuration first. This will be explained in the next section.

## Installation

After compiling the project, copy the builds/libs/audiostreamerscrobbler-0.1.0-SNAPSHOT-all.jar file to a directory that is convenient for you. In the same directory, create a config.json file that looks like this:

    {
        "players" {
            "bluos": {
                "enabled": true,
                "players": ["Living Room C368"]
            }
            "musiccast": {
                "enabled": true,
                "players": ["Bedroom ISX-18D", "Kitchen WX-010"]
            }
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
            },
            "listenbrainz-server": {
                "enabled": true,
                "websiteUrl": "",
                "apiUrl": "",
                "userToken": ""
		    }
        },
        "settings": {
            "network": {
                "networkInterface": "",
                "networkInterfaceAddress": ""
            },
            "errorHandling": {
                "maxSongs": 100,
                "retryIntervalMinutes": 30
            }
        }
    }

This format may change once support for other player standards, new group functionality and/or other features are added to the program. I'll make sure this README.md file will always contain an up-to-date example.
	
### Setting up the players

The program can monitor all BluOS (Bluesound) and Yamaha MusicCast players that are available in your network.

Do not forget to disable the audiostreamer standards that you do not want to use at this time (by setting the "enabled" setting to value "false"). Otherwise, a lot of unnecessary traffic will be generated on your network.

#### Monitor BluOS (Bluesound) players

First, make sure that the "bluos" entry is enabled, as displayed below. Also, enter all the name of your players in the "names" field. 
For example if you have two players that are called "Living Room C368" and "Kitchen Pulse Flex", your BluOS players configuration will look like this:

        ...
        "players": {
			"bluos": {
				"enabled": "true",
				"players": ["Living Room C368", "Kitchen Pulse Flex"]
			}
        },
        ...

The player name must match your BluOS device name exactly. Note that the name is CaSe SeNsItIvE.

The program should be compatible with the new third party BluOS powered devices that have appeared on the market (I believe Dali has them), but this has not been tested yet.

#### Monitor a Yamaha MusicCast player

At this stage, the program can only monitor the Net/USB input of MusicCast players. Also, despite some players having support for multiple zones, only the Main zone is supported for now. I hope to improve this one day.

First, make sure that the "musiccast" entry is enabled, as displayed below. Also, enter all the name of your players in the "names" field. 
For example if you have two players that are called "Living Room WX-010" and "Bedroom ISX-18D", your MusicCast players configuration will look like this:

        ...
        "players": {
			"musiccast": {
				"enabled": "true",
				"players": ["Living Room WX-010", "Bedroom ISX-18D"]
			}
        },
        ...

Note that the player name is case sensitive.

I have seen that when playing local songs from my NAS, that the MusicCast player does not recognize the length of songs and therefore cannot scrobble those songs. Yamaha UK support team confirmed to me that this is a known current implementation limitation of the MusicCast platform. I'll do some investigating and try to come up with an optional workaround.

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

#### ListenBrainz and ListenBrainz Server

[ListenBrainz](https://listenbrainz.org) is a new service, operated by the [MetaBrainz Foundation](https://metabrainz.org). At the time of writing this service was still in beta. A big different with all others  is that ListenBrainz will give away all collected data for free. Everybody can download a complete data dumps from their database on their website. A recommondation system is said to be in development.

To use this program with ListenBrainz, first get yourself an account. In your user profile, you'll find your unique user token. Copy and paste this and place this in the "userToken" field of the "listenbrainz" entry in the config.json file. Don't forget to set the "enabled" field to the "true" value.

##### Local installation

You can also choose to download the [ListenBrainz Server](https://github.com/metabrainz/listenbrainz-server) yourself and run a server instance locally, but this is recommended for advanced users only. If you choose to go this route and have it running in your network, you must fill the "listenbrainz-server" entry in the config.json file, set its "enabled" field to "true" and fill the "websiteUrl" (the URL where you can access your local instance) and the "apiUrl" (this is the same URL that you entered in ListenBrainz Server's listenbrainz/config.py file's API URL field). You can keep it empty if you chose the same URL for the API as the website. You'll still need to find the User Token in your server's user profile page.

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

As this program was created for Raspberry pi-alike devices, it currently can only register songs that could not be scrobbled in volatile memory (storing them on the filesystem would damage the pi's SD cards on the long run). This means that the program will not persist them and when quitting the application before it had a chance to scrobble the songs, those scrobbles will be lost forever.

You can choose how many songs it can store per scrobbler by setting the desired amount in the "maxSongs" entry. You can also configure the interval on which it will try to scrobble those songs by setting the "retryIntervalMinutes" entry in the confgiuration file. This interval is always specified in minutes.

For Last FM, songs that could not be scrobbled for 14 days in a row are silently dropped, as required by Last FM. For the other services this limit has been set to 30 days.

### Configuring network interface parameters

Normally the program uses the network card that the Java's network library of the Java platform selects as its default. While developing, I have seen rare cases where the wrong network card was selected and the program could not communicate with any player on the network.

If this happens to you, you can overrule the network interface that is used when opening I/O sockets (at this time HTTP requests are not affected by this, open a GitHub issue if this causes problems for you).

To list the network interfaces that are available on your computer, run the following command:

    java -jar audiostreamerscrobbler-0.1.0-SNAPSHOT-all.jar --networkinterfaces

This will list the currently available and enabled network interfaces and their addresses. Sample output of my Windows desktop PC:

    Alias    : "wlan3"
    Name     : "Dell Wireless 1705 802.11b/g/n (2.4GHZ)"
    Addresses: "192.168.178.107"  "fe80:0:0:0:49bc:efb0:4553:60e2%wlan3"

    Alias    : "eth6"
    Name     : "VirtualBox Host-Only Ethernet Adapter"
    Addresses: "192.168.99.1"  "fe80:0:0:0:a949:fd47:3561:4b76%eth6"

In the config.json configuration file, find or add the "network" section under "settings":

    ...
	"settings": {
	    ....
	    "network": {
			"networkInterface": "wlan3",
			"networkInterfaceAddress": ""
		},
	    ....
    }
    ...

In the `networkInterface` field, you can fill the output of the `Alias` or `Name` fields, that were listed when using the `--networkinterfaces` parameter.
Normally that would be enough, the program will then try to bind to the first IP address of that network interface. If you want the program to bind to a specific IP address of a network interface, you can also fill the `networkInterfaceAddress` field. For example, on my system I could fill `networkInterfaceAddress` with the `"192.168.178.107"` address.
	
## Plans

At the top of my list is improving the support of multiple players. After that, I'd like to add an optional GUI mode to make it possible to configure the program in a much more user-friendly way.

Then, I'd like to add HEOS by Denon support. Please let me know if there's any demand for support of other types/brands of audio streamers.

On the longer term I'd like to add more advanced grouping possibilities, so that different group of devices can scrobble to different accounts on different services.

Right now I mostly concentrate on features that I'll use myself, but if there's demand I'd love to switch priorities.

## About the author

I am Vincent van der Leun. I'm a Dutch Java developer and currently employed by a modern cloud-based software company in Woerden.

If you like scrobbling as much as I do, feel free to add me on one of the following public music tracking services:

* Last FM: https://www.last.fm/user/vvdleun
* ListenBrainz: https://listenbrainz.org/user/vintzend
* Libre FM: https://libre.fm/user/vintzend

Also, please open GitHub issues if you need support, have questions, concerns, suggestions, etc. about this program.
