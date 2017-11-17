{expect} = require 'chai'
seneca = require 'seneca'
env = require('dotenv').config({path: "#{__dirname}/../../../secrets.env"})
plugin_in_test = require "#{__dirname}/../../src/plugins/wit_ai/"

_outside_action_args = {}

_wit_response =
  msg_id: 'SOME_WIT_AI_ID'
  _text: 'Add an important todo for tomorrow at 1pm and 3pm'
  entities:
    reminder:[
      {
        value: 'an important todo'
        confidence: .65
      }
    ]
    datetime:[
      {
        value: '2017-11-17T13:00:00.000-08:00'
        confidence: .95
      }
      {
        value: '2017-11-16T15:00:00.000-08:00'
        confidence: .80
      }
    ]
    intent: [
      {
        confidence: .75
        value: 'add_todo'
      }
    ]

_outside_action_args = {}

_action_opts =
  role: 'wit_ai'
  cmd: 'parse_response'
  raw_wit_response: _wit_response

_fresh_instance = ()->
  fresh_instance = seneca log: 'test'
    .add 'role:util,cmd:missing_args', (msg, reply)->
      msg.given = @util.clean msg.given
      _outside_action_args['util-missing_args'] = @util.clean msg
      reply null, data:{}
    .use plugin_in_test
  fresh_instance

describe '|--- role: WIT_AI cmd: PARSE_RESPONSE ---|', ->
  describe 'bootstrapping', ->
    bootstrapped_instance = null
    before 'create instance and save when ready', (done)->
      test_instance = _fresh_instance()
        .test done
        .ready ->
          bootstrapped_instance = test_instance
          done()
    it 'registers the pattern role:wit_ai,cmd:parse_response', ->
      pattern_exists = bootstrapped_instance.has 'role:wit_ai,cmd:parse_response'
      expect(pattern_exists).to.equal true
  describe 'handling action args without raw_wit_response', ->
    bad_action_opts = Object.assign {}, _action_opts, raw_wit_response: null
    action_response = null
    before 'start fresh instance, send bad action, and save response', (done)->
      _fresh_instance()
      .test done
      .ready ->
        @act bad_action_opts, (err, response)->
          action_response = response
          done()
    it 'sends back an error', ->
      expect(action_response).to.include.keys 'err'
    it 'calls the error handler', ->
      expect(_outside_action_args).to.include.keys 'util-missing_args'
    it "passes its arguments to the err handler as the 'given' key", ->
      handler_opts = _outside_action_args['util-missing_args']
      expect(handler_opts.given).to.deep.equal bad_action_opts

  describe 'handling correct action args', ->
    action_response = null
    before 'send action and save response', (done)->
      _fresh_instance()
      .test done
      .ready ->
        @act _action_opts, (err, response)->
          action_response = response
          done()
    it 'returns the parsed wit response', ->
      expect(action_response).to.include.keys 'data'
      expect(action_response.data).to.be.an 'object'
    it 'parses each of the keys on the raw response', ->
