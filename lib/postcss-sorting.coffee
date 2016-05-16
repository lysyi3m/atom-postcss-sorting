fs = require 'fs'
path = require 'path'
postcss = sorting = null

module.exports =
  config:
    preset:
      title: 'Preset'
      description: 'Select sorting preset (zen, csscomb or yandex)'
      type: 'string'
      default: 'default'
      enum: ['default', 'zen', 'csscomb', 'yandex']

  activate: ->
    atom.commands.add 'atom-text-editor', 'postcss-sorting:run', =>
      @sort atom.workspace.getActivePaneItem()

  sort: (editor) ->
    postcss ?= require 'postcss'
    sorting ?= require 'postcss-sorting'
    config = atom.config.get 'postcss-sorting'
    preset = config.preset
    selection = editor.getSelectedText()
    buffer = editor.getBuffer()

    src =
      content: if selection.length then selection else buffer.getText()
      isSelection: selection.length > 0

    options = null
    optionsPath = atom.project.getDirectories()[0]?.resolve '.postcss-sorting.json'

    if fs.existsSync optionsPath
      try
        options = JSON.parse(fs.readFileSync(optionsPath))
      catch
        options = null

    postcss([sorting ( options )]).process(src.content, preset).then((result) ->
      if src.isSelection
        editor.insertText(result.css)
      else
        editor.setText(result.css)
      atom.notifications?.addSuccess(if options then "Successfully sorted using custom '.postcss-sorting.json' file." else "Successfully sorted using '#{preset}' preset.")
    ).catch (error) ->
      atom.notifications?.addError("Sorting error: '#{error.reason}'.", {detail: error.message})
