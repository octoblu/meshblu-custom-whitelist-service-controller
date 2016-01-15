http    = require 'http'
request = require 'request'
shmock  = require '@octoblu/shmock'
Server  = require '../server'

describe 'Hello', ->
  beforeEach (done) ->
    @meshblu = shmock 0xd00d

    @service =
      actionYo: sinon.stub()

    serverOptions =
      port: undefined,
      disableLogging: true
      service: @service

    meshbluConfig =
      server: 'localhost'
      port: 0xd00d

    @server = new Server serverOptions, {meshbluConfig}

    @server.run =>
      @serverPort = @server.address().port
      done()

  afterEach (done) ->
    @server.stop done

  afterEach (done) ->
    @meshblu.close done

  describe 'POST /message', ->
    beforeEach ->
      @receiverDevice =
        uuid: 'receiver-uuid'
        token: 'receiver-token'
        customWhitelists:
          actionYo: ['someone-who-can-actionYo']

      @receiverAuth = new Buffer('receiver-uuid:receiver-token').toString 'base64'

      @authDevice = @meshblu
        .get '/v2/whoami'
        .set 'Authorization', "Basic #{@receiverAuth}"
        .reply 200, uuid: 'receiver-uuid', token: 'receiver-token'

      @meshblu
        .get '/v2/devices/receiver-uuid'
        .set 'Authorization', "Basic #{@receiverAuth}"
        .reply 200, @receiverDevice

    describe 'when the method exists on the service', ->
      beforeEach (done) ->
        options =
          uri: '/message'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'receiver-uuid'
            password: 'receiver-token'
          json:
            fromUuid: 'someone-who-can-actionYo'
            metadata:
              type: 'actionYo'
            data:
              yo: 'mama'

        request.post options, (error, @response, @body) => done error
        @service.actionYo.yields null, 'sup'

      it 'should auth handler', ->
        @authDevice.done()

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200

    describe 'when the method doesn\'t on the service', ->
      beforeEach (done) ->
        options =
          uri: '/message'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'receiver-uuid'
            password: 'receiver-token'
          json:
            fromUuid: 'someone-who-can-actionYo'
            metadata:
              type: 'stealMoney'
            data:
              yo: 'mama'

        request.post options, (error, @response, @body) => done error

      it 'should return a 422', ->
        expect(@response.statusCode).to.equal 422
