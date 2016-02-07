fs = require 'fs'
postcss = require 'postcss'
sorting = require 'postcss-sorting'

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
    config = atom.config.get 'postcss-sorting'
    preset = config.preset
    selection = editor.getSelectedText()

    src =
      path: editor.getPath()
      content: if selection.length then selection else fs.readFileSync(editor.getPath())
      isSelection: selection.length > 0

    postcss([sorting]).process(src.content, preset).then((result) ->
      if src.isSelection
        editor.insertText(result.css)
      else
        fs.writeFileSync(src.path, result.css)
      atom.notifications?.addSuccess("Successfully sorted using '#{preset}' preset.")
    ).catch (error) ->
      atom.notifications?.addError("Sorting error: '#{error.reason}'.", {detail: error.message})
