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
  allowedGrammas: ['css', 'less', 'scss', 'postcss']
  editorObserver: null
  subs: null

  activate: ->
    @subs = atom.commands.add 'atom-text-editor', 'postcss-sorting:run', =>
      @sort atom.workspace.getActivePaneItem()
    @editorObserver = atom.workspace.observeTextEditors (editor) =>
      @_handleEvents editor

  _handleEvents: (editor) ->
    editor.getBuffer().onWillSave =>
      if @_isOnSave() and @_isAllowedGrama(editor)
        @sort atom.workspace.getActivePaneItem()

  _getOptionsPaths: ->
    config = atom.config.get 'postcss-sorting'
    HOME = process.env.HOME
    optionsPaths = ['.postcss-sorting.json', 'package.json']

    if config.customConfig
      optionsPaths.push config.customConfig.replace(/^~/, HOME)

    optionsPaths.push "#{HOME}/#{optionsPaths[0]}"

    optionsPaths

  _getPredefinedConfig: ->
    pluginPath = atom.packages.resolvePackagePath 'postcss-sorting'
    config = atom.config.get 'postcss-sorting'
    predefinedConfigPath = "#{pluginPath}/lib/presets/#{config.preset}.json"
    predefinedConfig = null

    if fs.existsSync predefinedConfigPath
      predefinedConfig = JSON.parse(fs.readFileSync(predefinedConfigPath))

    predefinedConfig

  _customConfigExist: ->
    config = atom.config.get 'postcss-sorting'
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
    config = atom.config.get 'postcss-sorting'
    if config.checkForConfigFile
      config.shouldUpdateOnSave && @_customConfigExist()
    else
      config.shouldUpdateOnSave

  _isAllowedGrama: (editor) ->
    currentGrammar = editor.getGrammar().name.toLowerCase()
    @allowedGrammas.includes currentGrammar

  sort: (editor) ->
    postcss ?= require 'postcss'
    sorting ?= require 'postcss-sorting'
    config = atom.config.get 'postcss-sorting'
    preset = config.preset
    {path} = atom.project.getDirectories()[0]
    selection = editor.getSelectedText()
    buffer = editor.getBuffer()
    grammar = editor.getGrammar()
    predefinedConfig = @_getPredefinedConfig()
    options = null

    switch grammar.scopeName
      when 'source.css.postcss.sugarss'
        syntax = require 'sugarss'
      when 'source.css.less'
        syntax = require 'postcss-less'
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
        cursorPosition = editor.getCursorScreenPosition()

        if src.isSelection
          editor.insertText(result.css)
        else
          editor.setText(result.css)

        editor.setCursorScreenPosition(cursorPosition)

        if config.notify
          usedPreset = if options then "custom '#{optionsPath}' file." else "'#{preset}' preset."
          atom.notifications?.addSuccess("Successfully sorted using #{usedPreset}")

      .catch (error) =>
        message = "Sorting error: '#{error.reason}'."
        atom.notifications?.addError(message, {detail: error.message})

  deactivate: ->
    @subs.dispose()
    @editorObserver.dispose()
