fs = require 'fs'
{resolve} = require 'path'
postcss = sorting = null

module.exports =
  config:
    customConfig:
      description: 'Custom path to config file.'
      type: 'string'
      default: ''
    preset:
      description: 'Fallback to this preset in the absence of a config file.'
      type: 'string'
      default: 'default'
      enum: ['default', 'zen', 'csscomb', 'yandex']
    notify:
      description: 'Display notification on successful sort.'
      type: 'boolean'
      default: true

  activate: ->
    @subs = atom.commands.add 'atom-text-editor', 'postcss-sorting:run', =>
      @sort atom.workspace.getActivePaneItem()

  sort: (editor) ->
    postcss ?= require 'postcss'
    sorting ?= require 'postcss-sorting'
    config = atom.config.get 'postcss-sorting'
    preset = config.preset
    HOME = process.env.HOME
    {path} = atom.project.getDirectories()[0]
    selection = editor.getSelectedText()
    buffer = editor.getBuffer()

    src =
      content: if selection.length then selection else buffer.getText()
      isSelection: selection.length > 0

    optionsPaths = ['.postcss-sorting.json', 'package.json']
    if config.customConfig
      optionsPaths.push config.customConfig.replace(/^~/, HOME)
    optionsPaths.push "#{HOME}/#{optionsPaths[0]}"

    for optionsPath in optionsPaths
      optionsPath = resolve(path, optionsPath)
      if fs.existsSync optionsPath
        try
          options = JSON.parse(fs.readFileSync(optionsPath))
          if optionsPath.endsWith(optionsPaths[1])
            options = options.postcssSortingConfig ? null
            throw {} unless options
          break

    postcss([ sorting (options) ])
      .process(src.content, preset)
      .then (result) ->
        if src.isSelection
          editor.insertText(result.css)
        else
          editor.setText(result.css)

        if config.notify
          message =
            if options
              "custom '#{optionsPath}' file."
            else "'#{preset}' preset."
          atom.notifications?.addSuccess("Successfully sorted using #{message}")

      .catch (error) =>
        message = "Sorting error: '#{error.reason}'."
        atom.notifications?.addError(message, {detail: error.message})

  deactivate: -> @subs.dispose()
