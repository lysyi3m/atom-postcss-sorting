# atom-postcss-sorting
[![apm](https://img.shields.io/apm/v/postcss-sorting.svg)]()
[![apm](https://img.shields.io/apm/dm/postcss-sorting.svg)](https://atom.io/packages/postcss-sorting)

![Screenshot](https://lysyi3m-pluto.s3.amazonaws.com/dropshare/Screen-Recording-2016-03-31-02-15-19.gif)

Atom editor plugin to sort CSS rules content with specified order. The following syntaxes are currently supported: CSS, SASS/SCSS and PostCSS (aka SugarSS).

## Installation

```
$ apm install postcss-sorting
```
or open Atom and go to Preferences > Install and search for `postcss-sorting` package.

## Options

You can select one of the bundled presets: _default_, _csscomb_, _yandex_ and _zen_.

If any of the following config files exist, they will override the selected preset. They are loaded in the following order of priority:

1. `.postcss-sorting.json` or `postcss-sorting.json` at the root of your project

2. A `"postcssSortingConfig": { ... }` object in your project `package.json`

3. Custom `~/path/to/your/config.json` (if specified in package settings)

4. `~/.postcss-sorting.json` or `~/postcss-sorting.json` file in your `HOME` directory

Files can be processed "On Save" (not enabled by default).

"On Save" can be disabled if no config file is present (not enabled by default).

Notifications can also be disabled from the package settings.

## Usage

In a CSS or PostCSS file, open the Command Palette (<kbd>Cmd</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd> (OS X), <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd> (Windows/Linux)) and choose `PostCSS Sorting: Run`.

Keyboard shortcut: <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd>

If you have an "On Save" option enabled and "Check for config file" option disabled just save a file.

## Acknowledgements

This plugin is based on the [postcss-sorting](https://github.com/hudochenkov/postcss-sorting) plugin by [Aleks Hudochenkov](https://github.com/hudochenkov)
