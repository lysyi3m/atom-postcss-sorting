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
      order: 1
    preset:
      description: 'Fallback to this preset in the absence of a config file.'
      type: 'string'
      default: 'default'
      enum: ['default', 'zen', 'csscomb', 'yandex', 'smacss']
      order: 2
    notify:
      description: 'Display notification on successful sort.'
      type: 'boolean'
      default: true
      order: 3
    shouldUpdateOnSave:
      title: 'On Save'
      description: 'Process file on every save.'
      type: 'boolean'
      default: false
      order: 4
    checkForConfigFile:
      title: 'Check for config file to enable On Save processing'
      description: "You can enable On Save globally or only if the config file exists.\n\n
        This still requires On Save option to be enabled."
      type: 'boolean'
      default: false
      order: 5

  _allowedGrammars: ['css', 'scss', 'postcss']
  _editorObserver: null
  _subs: null

  activate: ->
    @_subs = atom.commands.add 'atom-text-editor', 'postcss-sorting:run', =>
      @_sort atom.workspace.getActivePaneItem()
    @_editorObserver = atom.workspace.observeTextEditors (editor) =>
      @_handleEvents editor

  _handleEvents: (editor) ->
    editor.getBuffer().onWillSave =>
      if @_isOnSave() and @_isAllowedGramar(editor)
        @_sort atom.workspace.getActivePaneItem()

  _getOptionsPaths: ->
    @_config ?= atom.config.get 'postcss-sorting'
    HOME = process.env.HOME
    optionsPaths = [
      '.postcss-sorting.json',
      'postcss-sorting.json',
      'package.json'
    ]

    if @_config.customConfig
      optionsPaths.push @_config.customConfig.replace(/^~/, HOME)

    optionsPaths.push "#{HOME}/.postcss-sorting.json", "#{HOME}/postcss-sorting.json"

    optionsPaths

  _getPredefinedConfig: ->
    @_config ?= atom.config.get 'postcss-sorting'
    pluginPath = atom.packages.resolvePackagePath 'postcss-sorting'
    predefinedConfigPath = "#{pluginPath}/lib/presets/#{@_config.preset}.json"
    predefinedConfig = null

    if fs.existsSync predefinedConfigPath
      predefinedConfig = JSON.parse(fs.readFileSync(predefinedConfigPath))

    predefinedConfig

  _customConfigExist: ->
    @_config ?= atom.config.get 'postcss-sorting'
    {path} = atom.project.getDirectories()[0]
    optionsPaths = @_getOptionsPaths()
    configExist = false

    for optionsPath in optionsPaths
      optionsPath = resolve(path, optionsPath)

      if fs.existsSync optionsPath
        if optionsPath.endsWith('package.json')
          options = JSON.parse(fs.readFileSync(optionsPath))
          if options.postcssSortingConfig
            configExist = true
        else
          configExist = true
        break

    configExist

  _isOnSave: ->
    @_config ?= atom.config.get 'postcss-sorting'

    if @_config.checkForConfigFile
      @_config.shouldUpdateOnSave && @_customConfigExist()
    else
      @_config.shouldUpdateOnSave

  _isAllowedGramar: (editor) ->
    currentGrammar = editor.getGrammar().name.toLowerCase()
    @_allowedGrammars.includes currentGrammar

  _sort: (editor) ->
    postcss ?= require 'postcss'
    sorting ?= require 'postcss-sorting'
    @_config ?= atom.config.get 'postcss-sorting'
    preset = @_config.preset
    {path} = atom.project.getDirectories()[0]
    selection = editor.getSelectedText()
    buffer = editor.getBuffer()
    grammar = editor.getGrammar()
    predefinedConfig = @_getPredefinedConfig()
    options = null

    if grammar.scopeName == 'source.css.postcss.sugarss'
      syntax = require 'sugarss'
    else
      syntax = require 'postcss-scss'

    src =
      content: if selection.length then selection else buffer.getText()
      isSelection: selection.length > 0

    optionsPaths = @_getOptionsPaths()

    for optionsPath in optionsPaths
      optionsPath = resolve(path, optionsPath)

      if fs.existsSync optionsPath
        try
          options = JSON.parse(fs.readFileSync(optionsPath))
          if optionsPath.endsWith('package.json')
            options = options.postcssSortingConfig ? null
            throw {} unless options
          break

    postcss([ sorting (options || predefinedConfig) ])
      .process(src.content, { syntax: syntax })
      .then (result) =>
        shouldUpdateContent = src.content != result.css

        return if !shouldUpdateContent

        cursorPosition = editor.getCursorScreenPosition()

        if src.isSelection
          editor.insertText(result.css)
        else
          editor.setText(result.css)

        editor.setCursorScreenPosition(cursorPosition)

        if @_config.notify
          usedPreset = if options then "custom '#{optionsPath}' file." else "'#{preset}' preset."
          atom.notifications?.addSuccess("Successfully sorted using #{usedPreset}")

      .catch (error) ->
        message = "Sorting error: '#{error.reason}'."
        atom.notifications?.addError(message, {detail: error.message})

  deactivate: ->
    @_subs.dispose()
    @_editorObserver.dispose()
