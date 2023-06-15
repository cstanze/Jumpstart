# Jumpstart

Quickly set up Arch Linux installations using simple dialog prompts, similar to `archinstall` (except cooler because we use `dialog` and not boring text interfaces)

## How do I use it?

Arch Linux installations are usually in two parts:

1. Bootstrapping
2. Configuration

Bootstrapping consists of setting up things like the mirror region, drive layout, and the final `pacstrap` before configuration.

Configuration is where the real stuff happens for the system you'll be using. This includes timezone, locale, networking, initramfs, and the likes.

So for that, we have two main scripts. `bootstrap.sh` and `configure.sh` where the separate sections will be done (and won't allow you to continue without the previous section being finished)
