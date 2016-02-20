## Logitech G710+ without "Gaming Sotware"

**TL;DR**

Run this command line tool on **Mac OS** to use the **G1-6 keys** of the Logitech **G710+ gaming keyboard** without installing proprietary Software by Logitech.

### Introduction

So you just bought this gaming keyboard and realize "oh no, the G-keys don't work without the Logitech spyware drivers :("

"No problem", you say, "I'll install [https://github.com/tekezo/Karabiner/](Karabiner) and remap them manually" - only to find out that the G-keys simply mirror the numeric 1-6 keys, which makes them indistinguishable.

Digging in deeper, you might find out that [someone reverse engineered](https://github.com/K900/g710) the USB communication of the keyboard. It turns out that you can instruct the keyboard to stop mirroring the number keys.

### How it works

This is a simple command line application written in Swift that communicates directly via USB with your keyboard and does the following:

* Whenever you plug in the keyboard, it will stop mirroring the numbers 1-6 when pressing the G-keys
* When pressing the G-keys the **numpad** 1-6 keys are triggered instead.
* When switching to M2, the numpad 7-9 *, - and / keys are trieggered instead
* When switching to M3, the G keys don't do anything, which allows you to use the original Gaming Software on-the-fly

In effect, this allows you to use the keyboard in games without any Logitech driver.

### Try it out

Start a Terminal and run this curl command to get the executable:

```bash
sudo bash -c "curl -L https://github.com/halo/macosvpn/releases/download/0.1.0/g710plus > /usr/local/bin/g710plus"
sudo chmod +x /usr/local/bin/g710plus
```

Then just give it a try by running `g710plus --verbose`. The verbose flag is only for you to see some output on what is happening behind the scenes.

If it works well for you, you can have your Mac to always keep the program running. To do this, create a file called `com.funkensturm.g710plus.plist` in the directory `~/Library/LaunchAgents` with the following content:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>KeepAlive</key>
	<true/>
	<key>Label</key>
	<string>com.funkensturm.g710plus</string>
	<key>ProgramArguments</key>
	<array>
		<string>/usr/local/bin/g710plus</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
```

And run

```bash
launchctl load ~/Library/LaunchAgents/com.funkensturm.g710plus.plist
```

to start the daemon immeadiately. Even if you don't start it immediately, you could now log out and login and the application will run in the background.

### Limitations

* There is no key-repeat. You press a G key once and it triggers once.

### Credits

* [K900 libusb python script](https://github.com/K900/g710)
* [Eric Betts' KuandoSwift](https://github.com/bettse/KuandoSwift)

### License

Copyright (c) 2016 halo, MIT License

See each respective file or LICENSE.md for more details.
