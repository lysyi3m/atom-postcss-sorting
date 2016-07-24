fs = require 'fs'
{resolve} = require 'path'
postcss = null
sorting = null
syntax = null

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
    shouldUpdateOnSave:
      title: 'On Save'
      description: 'Process file on every save.'
      type: 'boolean'
      default: true
  allowedGrammas: ['css', 'less', 'scss']
  editorObserver: null
  subs: null

  activate: ->
    @subs = atom.commands.add 'atom-text-editor', 'postcss-sorting:run', =>
      @sort atom.workspace.getActivePaneItem()
    @editorObserver = atom.workspace.observeTextEditors((editor) =>
      @_handleEvents editor
    )

  _handleEvents: (editor) ->
    editor.getBuffer().onWillSave =>
      if @_isOnSave() and @_isAllowedGrama(editor)
        @sort atom.workspace.getActivePaneItem()

  _isOnSave: ->
    config = atom.config.get 'postcss-sorting'
    config.shouldUpdateOnSave

  _isAllowedGrama: (editor) ->
    @allowedGrammas.includes(editor.getGrammar().name.toLowerCase())

  sort: (editor) ->
    postcss ?= require 'postcss'
    sorting ?= require 'postcss-sorting'
    config = atom.config.get 'postcss-sorting'
    preset = config.preset
    HOME = process.env.HOME
    {path} = atom.project.getDirectories()[0]
    selection = editor.getSelectedText()
    buffer = editor.getBuffer()
    grammar = editor.getGrammar()

    if grammar.scopeName == 'source.css.postcss.sugarss'
      syntax = require 'sugarss'
    else
      syntax = require 'postcss-scss'

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
      .process(src.content, { preset, syntax: syntax })
      .then (result) =>
        if src.isSelection
          editor.insertText(result.css)
        else
          editor.setText(result.css)

        if config.notify
          message = if options then "custom '#{optionsPath}' file." else "'#{preset}' preset."
          atom.notifications?.addSuccess("Successfully sorted using #{message}")

      .catch (error) =>
        message = "Sorting error: '#{error.reason}'."
        atom.notifications?.addError(message, {detail: error.message})

  deactivate: ->
    @subs.dispose()
    @editorObserver.dispose()
