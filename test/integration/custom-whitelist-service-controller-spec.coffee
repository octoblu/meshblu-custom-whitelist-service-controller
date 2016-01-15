http    = require 'http'
request = require 'request'
shmock  = require '@octoblu/shmock'
Server  = require '../server'

describe 'Hello', ->
  beforeEach (done) ->
    @meshblu = shmock 0xd00d

    @service =
      actionYo: sinon.stub()
      checkTemp: sinon.stub().yields null, '98.6'
      spendMoney: sinon.stub().yields null, 'yay'

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
          checkTemp: ['*']

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
        @service.actionYo.yields null, greeting: 'sup'

      it 'should auth handler', ->
        @authDevice.done()

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200

      it 'should give us the correct data', ->
        expect(@body.data).to.deep.equal greeting: 'sup'

      it 'should call the service with the correct data', ->
        expect(@service.actionYo).to.have.been.calledWith yo: 'mama',

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

    describe 'when the method exists on the service, but the user isn\'t in the custom whitelist', ->
      beforeEach (done) ->
        options =
          uri: '/message'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'receiver-uuid'
            password: 'receiver-token'
          json:
            fromUuid: 'someone-who-cant-actionYo'
            metadata:
              type: 'actionYo'

        request.post options, (error, @response, @body) => done error

      it 'should return a 403', ->
        expect(@response.statusCode).to.equal 403

    describe 'when the method exists on the service, and the whitelist contains a *', ->
      beforeEach (done) ->
        options =
          uri: '/message'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'receiver-uuid'
            password: 'receiver-token'
          json:
            fromUuid: 'someone-who-cant-actionYo'
            metadata:
              type: 'checkTemp'

        request.post options, (error, @response, @body) => done error

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200

    describe 'when the method exists on the service, and there is no whitelist, but you are yourself', ->
      beforeEach (done) ->
        options =
          uri: '/message'
          baseUrl: "http://localhost:#{@serverPort}"
          auth:
            username: 'receiver-uuid'
            password: 'receiver-token'
          json:
            fromUuid: 'receiver-uuid'
            metadata:
              type: 'spendMoney'

        request.post options, (error, @response, @body) => done error

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200
