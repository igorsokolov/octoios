octoios
=======

Scripts for automatic build, deploy and launch iOS apps on connected Apple devices.

# About

- Builds .app application with `xcodebuild` command if -n flag is not used.
- Run `fruitstrap` to upload application to all connected devices.
- Uses `instruments` command to run applications.

# Requirements

- Xcode should be installed.
- Keychain should be accessible without password. To unlock keychain:

        $ secure unlock -p <password> {$HOME}/Library/Keychains/login.keychain

- Valid provisioning profile and signing certificate should be installed. [Apple developers center](https://developer.apple.com/ "Apple developers center")

# Usage

    $ ./octoios.rb [options]

    Options:
      -s, --schema SCHEMA              Application schema to use with build command
      -i, --bundle_id BUNDLE_ID        Bundle identifier of application
      -b, --build_dir BUILD_DIR        Builds directory (default: {current_folder}/builds)
      -r, --src_dir SRC_DIR            Project source folder (where .xcodeproj file is located)
      -n, --no_build                   Don't build project, .app or .ipa app should exists in a BUILD_DIR
      -h, --help                       Shows help message

# Acknowledgments:


The following 3rd party open source libraries have been used:


- Fruitstrap (authored by ghughes, mantained by jgranick, minor fix by igorsokolov) [Fruitstrap](https://github.com/igorsokolov/fruitstrap)
- Transported Chief (authored by [Holger Weissböck](http://gamua.com/blog/2012/03/how-to-deploy-ios-apps-to-the-iphone-via-the-command-line/)) [Transporter chief](https://gist.github.com/3096433)

# TODO:

- Run the script as a daemon (add `-d` option)
- Handle USR1 signal to install and start App ( respect `--no_build` option )
- Support optional config file for options (YAML)
- Add more todos :)