async         = require 'async'
MeshbluConfig = require 'meshblu-config'
MeshbluXMPP   = require 'meshblu-xmpp'

TARGET_UUID = '46521873-cbbe-4cc9-ae0b-18753591d027'

class Command
  panic: (error) =>
    console.error error.stack
    process.exit 1

  run: =>
    @config = (new MeshbluConfig()).toJSON()
    @meshblu = new MeshbluXMPP @config
    @meshblu.connect (error) =>
      return @panic error if error?
      console.log 'connected'
      @subscribe()
      @update()

    @meshblu.on 'error', @panic
    @meshblu.on 'message', @onMessage

  onMessage: (message) =>
    console.log 'message', JSON.stringify(message, null, 2)

  subscribe: =>
    subscriptions = [{
      type: 'configure.received'
      emitterUuid: @config.uuid
      subscriberUuid: @config.uuid
    }, {
      type: 'configure.sent'
      emitterUuid: TARGET_UUID
      subscriberUuid: @config.uuid
    }, {
      type: 'broadcast.received'
      emitterUuid: @config.uuid
      subscriberUuid: @config.uuid
    }, {
      type: 'broadcast.sent'
      emitterUuid: TARGET_UUID
      subscriberUuid: @config.uuid
    },{
      type: 'message.received'
      emitterUuid: @config.uuid
      subscriberUuid: @config.uuid
    }]

    async.each subscriptions, async.apply(@meshblu.subscribe, @config.uuid), (error) =>
      return @panic error if error?
      console.log 'subscribed'

  update: =>
    operations = [
      $unset:
        discoverWhitelist: 1
        configureWhitelist: 1
        sendWhitelist: 1
        receiveWhitelist: 1
        'meshblu.forwarders': 1
    ,
      $set:
        'meshblu.version': '2.0.0'
        'meshblu.whitelists.message.from': {"#{TARGET_UUID}": {}}
        'meshblu.forwarders.broadcast.received': [{
          type:   'webhook'
          url:    'http://requestb.in/1hp0fw11'
          method: 'POST'
        }]
        'meshblu.forwarders.configure.received': [{
          type:   'webhook'
          url:    'http://requestb.in/1hp0fw11'
          method: 'POST'
        }]
        'meshblu.forwarders.message.received': [{
          type:   'webhook'
          url:    'http://requestb.in/1hp0fw11'
          method: 'POST'
        }]
    ]
    async.each operations, async.apply(@meshblu.update, @config.uuid), (error) =>
      return @panic error if error?
      console.log 'updated'
      @whoami()

  whoami: =>
    @meshblu.whoami (error, device) =>
      console.log 'whoami', JSON.stringify(device, null, 2)

module.exports = Command
