CustomWhitelistServiceController = require '../src/controllers/custom-whitelist-service-controller'

class Router
  constructor: ({@service}) ->

  route: (app) =>
    customWhitelistServiceController = new CustomWhitelistServiceController {@service}
    app.post '/message', customWhitelistServiceController.message

module.exports = Router
