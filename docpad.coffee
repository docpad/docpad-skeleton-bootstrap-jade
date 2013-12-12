# The DocPad Configuration File
# It is simply a CoffeeScript Object which is parsed by CSON
docpadConfig =

  # Template Data
  # =============
  # These are variables that will be accessible via our templates
  # To access one of these within our templates, refer to the FAQ: https://github.com/bevry/docpad/wiki/FAQ

  templateData:

    # Specify some site properties
    site:
      # The production url of our website
      url: "http://website.com"

      # Here are some old site urls that you would like to redirect from
      oldUrls: [
        'www.website.com',
        'website.herokuapp.com'
      ]

      # The default title of our website
      title: "Your Website"

      # The website description (for SEO)
      description: """
        When your website appears in search results in say Google, the text here will be shown underneath your website's title.
        """

      # The website keywords (for SEO) separated by commas
      keywords: """
        place, your, website, keywoards, here, keep, them, related, to, the, content, of, your, website
        """

      # The website author's name
      author: "Your Name"

      # The website author's email
      email: "your@email.com"

      # Your company's name
      copyright: "© Your Company 2012"


    # Helper Functions
    # ----------------

    # Get the prepared site/document title
    # Often we would like to specify particular formatting to our page's title
    # we can apply that formatting here
    getPreparedTitle: ->
      # if we have a document title, then we should use that and suffix the site's title onto it
      if @document.title
        "#{@document.title} | #{@site.title}"
      # if our document does not have it's own title, then we should just use the site's title
      else
        @site.title

    # Get the prepared site/document description
    getPreparedDescription: ->
      # if we have a document description, then we should use that, otherwise use the site's description
      @document.description or @site.description

    # Get the prepared site/document keywords
    getPreparedKeywords: ->
      # Merge the document keywords with the site keywords
      @site.keywords.concat(@document.keywords or []).join(', ')

    getGruntedStyles: ->
      _ = require 'underscore'
      styles = []
      gruntConfig = require('./grunt-config.json')
      _.each gruntConfig, (value, key) ->
        styles = styles.concat _.flatten _.pluck value, 'dest'
      styles = _.filter styles, (value) ->
        return value.indexOf('.min.css') > -1
      _.map styles, (value) ->
        return value.replace 'out', ''

    getGruntedScripts: ->
      _ = require 'underscore'
      scripts = []
      gruntConfig = require('./grunt-config.json')
      _.each gruntConfig, (value, key) ->
        scripts = scripts.concat _.flatten _.pluck value, 'dest'
      scripts = _.filter scripts, (value) ->
        return value.indexOf('.min.js') > -1
      _.map scripts, (value) ->
        return value.replace 'out', ''


  # Collections
  # ===========
  # These are special collections that our website makes available to us

  collections:
    # For instance, this one will fetch in all documents that have pageOrder set within their meta data
    pages: (database) ->
      database.findAllLive({pageOrder: $exists: true}, [pageOrder:1,title:1])

    # This one, will fetch in all documents that will be outputted to the posts directory
    posts: (database) ->
      database.findAllLive({relativeOutDirPath:'posts'},[date:-1])


  # DocPad Events
  # =============

  # Here we can define handlers for events that DocPad fires
  # You can find a full listing of events on the DocPad Wiki
  events:

    # Server Extend
    # Used to add our own custom routes to the server before the docpad routes are added
    serverExtend: (opts) ->
      # Extract the server from the options
      {server} = opts
      docpad = @docpad

      # As we are now running in an event,
      # ensure we are using the latest copy of the docpad configuraiton
      # and fetch our urls from it
      latestConfig = docpad.getConfig()
      oldUrls = latestConfig.templateData.site.oldUrls or []
      newUrl = latestConfig.templateData.site.url

      # Redirect any requests accessing one of our sites oldUrls to the new site url
      server.use (req,res,next) ->
        if req.headers.host in oldUrls
          res.redirect 301, newUrl+req.url
        else
          next()

    # Write After
    # Used to minify our assets with grunt
    writeAfter: (opts,next) ->
      # Prepare
      docpad = @docpad
      rootPath = docpad.config.rootPath
      balUtil = require 'bal-util'
      _ = require 'underscore'

      # Make sure to register a grunt `default` task
      command = ["#{rootPath}/node_modules/.bin/grunt", 'default']

      # Execute
      ##
      ## TO FIX: commented section works well, but grunt does not minify the css so the commented script erase the empty styles folder
      ##
      balUtil.spawn command, {cwd:rootPath,output:true}, ->
        # src = []
        # gruntConfig = require './grunt-config.json'
        # _.each gruntConfig, (value, key) ->
        #   src = src.concat _.flatten _.pluck value, 'src'
        # _.each src, (value) ->
        #   balUtil.spawn ['rm', value], {cwd:rootPath, output:false}, ->
        # balUtil.spawn ['find', '.', '-type', 'd', '-empty', '-exec', 'rmdir', '{}', '\;'], {cwd:rootPath+'/out', output:false}, ->
        next()

      # Chain
      @


# Export our DocPad Configuration
module.exports = docpadConfig
