fs = require 'fs'
postcss = require 'postcss'
sorting = require 'postcss-sorting'

module.exports =
  config:
    path:
      title: 'Config path'
      description: 'Absolute path to a JSON file'
      type: 'string'
      default: ''
    preset:
      title: 'Preset'
      description: 'Predefined config (will be used only if there is no custom config specified)'
      type: 'string'
      default: 'default'
      enum: ['default', 'zen', 'csscomb', 'yandex']


  activate: ->
    atom.commands.add 'atom-text-editor', 'postcss-sorting:run', =>
      @sort atom.workspace.getActivePaneItem()

  getSortingOptions: ->
    config = atom.config.get 'postcss-sorting'
    if fs.existsSync(config.path)
      fs.readFileSync config.path.trim(), 'utf8', (error, data) ->
        if error
          throw error
        return require(config.path)
    else
      atom.notifications?.addError("Failed to read config file '#{config.path}'!")
      return config.preset

  sort: (editor) ->
    options = @getSortingOptions()
    selection = editor.getSelectedText()

    src =
      path: editor.getPath()
      content: if selection.length then selection else fs.readFileSync(editor.getPath())
      isSelection: selection.length > 0

    postcss([sorting]).process(src.content, options).then((result) ->
      if src.isSelection
        editor.insertText(result.css)
      else
        fs.writeFileSync(src.path, result.css)
      atom.notifications?.addSuccess('Successfully sorted!')
    ).catch (error) ->
      atom.notifications?.addError("Sorting error: #{error.reason}", {detail: error.message})
