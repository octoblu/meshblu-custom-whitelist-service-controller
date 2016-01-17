Whitelist = require '../models/whitelist'
debug     = require('debug')('meshblu-rpc:controller')

class MeshbluRpcController
  constructor: ({@service}) ->

  message: (request, response) =>
    # job =
    #     metadata:
    #       auth: @auth
    #       toUuid: @auth.uuid
    #       jobType: 'SearchDevices'
    #     data:
    #       type: 'bug'

    {metadata, data} = request.body
    meshbluConfig = request.meshbluAuth
    toUuid = request.meshbluAuth.uuid
    {fromUuid} = request.body || toUuid

    jobType = metadata?.jobType
    data ?= {}

    return response.status(422).send error: 'metadata.jobType not specified' unless jobType?
    return response.status(422).send error: "jobType #{jobType} not recognized" unless @service[jobType]?
    debug "checking whitelist for rpc:", {jobType, data, metadata}

    whitelist = new Whitelist {whitelistName: jobType, meshbluConfig}

    whitelist.checkWhitelist {fromUuid, toUuid}, (error, allowed) =>
      return response.status(error.code || 500).send(error.message) if error?
      return response.sendStatus(403) unless allowed
      @service[jobType] data, meshbluConfig, (error, responseData) =>
        return response.status(error.code || 500).send(error.message) if error?
        response.status(200).send(data: responseData)

module.exports = MeshbluRpcController
