Whitelist = require '../models/whitelist'

class CustomWhitelistServiceController
  constructor: ({@meshbluConfig, @service}) ->

  message: (request, response) =>
    {metadata, data} = request.body
    meshbluConfig = request.meshbluAuth

    {fromUuid} = request.body
    toUuid = request.meshbluAuth.uuid

    return response.sendStatus 422 unless @service[metadata?.type]?

    whitelist = new Whitelist {whitelistName: metadata.type, meshbluConfig}

    whitelist.checkWhitelist {fromUuid, toUuid}, (error, allowed) =>
      return response.status(error.code || 500).send(error.message) if error?
      return response.sendStatus(403) unless allowed
      
      @service[metadata.type] data, meshbluConfig, (error, responseData) =>
        return response.status(error.code || 500).send(error.message) if error?
        response.status(200).send(data: responseData)

module.exports = CustomWhitelistServiceController
