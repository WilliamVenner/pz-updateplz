<p align="center">
	<img src="https://i.imgur.com/3yztk0D.png"/>
</p>

Don't you hate it when you try and join your server and it disconnects telling you there are outdated Workshop mods? Hate no more thanks to Update PLZ!

This mod will query the server's Workshop mods every minute and check if they were updated after the server started up. If it detects outdated Workshop items, the server will be saved & restarted the next time it is empty.


# For dedicated servers **ONLY**
This mod ONLY works on DEDICATED SERVERS and does nothing in co-op/singleplayer!


# How "restarting" works
This mod will SHUT DOWN the server - currently there is no way to RESTART the server from a mod, so please make sure you are using a daemon that will automatically restart the server when it shuts itself down.

If you don't currently have this setup for your server, you can find a simple script (bash script for Linux, Batch script for Windows) online for automatically restarting a program if it exits.


# Choosing the restart time
| **Mod ID**  | **Restarts after**            |
|-------------|-------------------------------|
| UpdatePlz   | When the server becomes empty |
| UpdatePlz1  | 1 minute                      |
| UpdatePlz5  | 5 minutes                     |
| UpdatePlz10 | 10 minutes                    |
| UpdatePlz15 | 15 minutes                    |
| UpdatePlz30 | 30 minutes                    |
| UpdatePlz60 | 1 hour                        |