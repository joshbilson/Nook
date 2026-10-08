# Personal Nook fork

Josh's fork of [nook-browser/nook](https://github.com/nook-browser/nook), built locally with no Apple
Developer account. Personal additions live in `personal/` so upstream merges stay clean.

```sh
personal/build-install.sh          # build + install to /Applications
personal/build-install.sh --sync   # merge upstream develop first, then build + install
```

Compared with upstream release builds, this one has no web push notifications and doesn't act as a system
AutoFill password provider (both need a paid Apple developer profile), and Sparkle auto-update is off so
upstream builds never replace it. See the comments in `build-install.sh` for the details.
