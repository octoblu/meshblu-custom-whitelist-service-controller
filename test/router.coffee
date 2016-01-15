MeshbluRpcController = require '../src/controllers/meshblu-rpc-controller'

class Router
  constructor: ({@service}) ->

  route: (app) =>
    meshbluRpcController = new MeshbluRpcController {@service}
    app.post '/meshblu-rpc', meshbluRpcController.message

module.exports = Router
