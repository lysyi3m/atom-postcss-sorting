fs = require 'fs'
postcss = require 'postcss'

module.exports =
  config:
    style:
      title: 'Format'
      description: 'Predefined config (affect only if there is no custom config location specified)'
      type: 'string'
      default: 'default'
      enum: ['default', 'zen', 'csscomb', 'yandex']
    path:
      title: 'Config path'
      description: 'Absolute path to custom config JSON file'
      type: 'string'
      default: ''

  activate: ->
    atom.commands.add 'atom-text-editor', 'postcss-sorting:run', =>
      @sort atom.workspace.getActivePaneItem()

  getSortingOptions: ->
    config = atom.config.get 'postcss-sorting'

    if fs.existsSync(config.path)
      fs.readFileSync config.path.trim(), 'utf8', (error, data) ->
        if error
          atom.notifications?.addError("Failed to read config file '#{config.path}'")
          throw error

        return require(config.path)
    else
      return config.style

  sort: (editor) ->
    options = @getSortingOptions()
    selection = editor.getSelectedText()

    src =
      path: editor.getPath()
      content: if selection.length then selection else fs.readFileSync(editor.getPath())
      isSelection: selection.length > 0

    postcss([
      require('postcss-sorting')
    ]).process(src.content, options).then((result) ->
      if src.isSelection
        editor.insertText(result.css)
      else
        fs.writeFileSync(src.path, result.css)
      atom.notifications?.addSuccess('PostCSS Sorting succeeded!')
    ).catch (error) ->
      atom.notifications?.addError("PostCSS Sorting error: #{error.reason}", {detail: error.message})
