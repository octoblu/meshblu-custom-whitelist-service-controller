_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'
debug       = require('debug')('meshblu-rpc:whitelist')

class Whitelist
  constructor: ({meshbluConfig, whitelistName}) ->
    @meshbluHttp = new MeshbluHttp meshbluConfig
    @whitelistPath = "customWhitelists.#{[whitelistName]}"

  checkWhitelist: ({fromUuid, toUuid}, callback) =>
    debug "checkWhitelist", {fromUuid, toUuid}

    return callback(null, false) unless fromUuid? && toUuid?
    return callback(null, true) if fromUuid == toUuid

    @meshbluHttp.device toUuid, (error, toDevice) =>
      debug "toDevice:", JSON.stringify toDevice, null, 2
      return callback(error) if error?
      whitelist = _.get toDevice, @whitelistPath

      return callback(null, true) if _.includes whitelist, '*'
      return callback(null, true) if _.includes whitelist, fromUuid
      return callback(null, false)

  addToWhitelist:({fromUuid, toUuid}, callback) =>
    whitelistUpdate = $addToSet: {}
    $addToSet[@whitelistPath] = toUuid
    @meshbluHttp.update fromUuid, whitelistUpdate, (error) =>
      return callback(error) if error?

module.exports = Whitelist
