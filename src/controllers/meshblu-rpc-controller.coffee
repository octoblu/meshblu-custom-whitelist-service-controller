Whitelist = require '../models/whitelist'

class MeshbluRpcController
  constructor: ({@meshbluConfig, @service}) ->

  message: (request, response) =>
    {metadata, data} = request.body
    meshbluConfig = request.meshbluAuth
    toUuid = request.meshbluAuth.uuid
    {fromUuid} = request.body || toUuid

    action = metadata?.action
    data ?= {}

    return response.status(422).send error: 'metadata.action not specified' unless action?
    return response.status(422).send error: "action #{action} not recognized" unless @service[action]?
    whitelist = new Whitelist {whitelistName: action, meshbluConfig}

    whitelist.checkWhitelist {fromUuid, toUuid}, (error, allowed) =>
      return response.status(error.code || 500).send(error.message) if error?
      return response.sendStatus(403) unless allowed
      @service[action] data, meshbluConfig, (error, responseData) =>
        return response.status(error.code || 500).send(error.message) if error?
        response.status(200).send(data: responseData)

module.exports = MeshbluRpcController
