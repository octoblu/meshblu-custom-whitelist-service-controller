_           = require 'lodash'
MeshbluHttp = require 'meshblu-http'

class Whitelist
  constructor: ({meshbluConfig, whitelistName}) ->
    @meshbluHttp = new MeshbluHttp meshbluConfig
    @whitelistPath = "customWhitelists.#{[whitelistName]}"

  checkWhitelist: ({fromUuid, toUuid}, callback) =>
    return callback(null, false) unless fromUuid? && toUuid?
    return callback(null, true) if fromUuid == toUuid

    @meshbluHttp.device toUuid, (error, toDevice) =>
      return callback(error) if error?
      whitelist = _.get toDevice, @whitelistPath
      return callback(null, true) if _.includes whitelist, '*'
      return callback(null, true) if _.includes whitelist, toUuid
      return callback(null, false)

  addToWhitelist:({fromUuid, toUuid}, callback) =>
    whitelistUpdate = $addToSet: {}
    $addToSet[@whitelistPath] = toUuid
    @meshbluHttp.update fromUuid, whitelistUpdate, (error) =>
      return callback(error) if error?

module.exports = Whitelist
