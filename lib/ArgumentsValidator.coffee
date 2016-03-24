
Map = require 'collections/fast-map'
_ = require 'lodash'
async = require 'async'
check = require 'check-types'
{ asyncLimit } = require './utils.coffee'

# Commands arguments type and count validation.
class ArgumentsValidator

  # @private
  # @nodoc
  constructor : (@server) ->
    @checkers = new Map
    for name, fn of @server.userCommands
      @checkers.set name, _.bind @[name], @
    @directMessagesChecker = @server.directMessagesChecker
    @roomMessagesChecker = @server.roomMessagesChecker
    @errorBuilder = @server.errorBuilder
    @customCheckers =
      directMessage : [ null, @directMessagesChecker ]
      roomMessage : [ null, @roomMessagesChecker ]

  # Check command arguments.
  #
  # @param name [String] Command name.
  # @param args [Rest...] Command arguments.
  # @param cb [Callback] Callback.
  checkArguments : (name, args..., cb) ->
    checkfn = @checkers.get name
    unless checkfn
      return process.nextTick =>
        cb @errorBuilder.makeError 'noCommand', name
    error = @checkTypes checkfn, args
    if error
      return process.nextTick -> cb error
    customCheckers = @customCheckers[name]
    if customCheckers
      async.forEachOfLimit customCheckers, asyncLimit
      , (checker, idx, fn) ->
        unless checker then return fn()
        checker args[idx], fn
      , cb
    else
      process.nextTick -> cb()

  # @private
  # @nodoc
  checkMessage : (msg) ->
    passed = check.object msg
    unless passed then return false
    passed = check.string msg.textMessage
    unless passed then return false
    _.keys(msg).length == 1

  # @private
  # @nodoc
  checkObject : (obj) ->
    check.object obj

  # @private
  # @nodoc
  checkTypes : (checkfn, args) ->
    checkers = checkfn()
    if args?.length != checkers.length
      return [ 'wrongArgumentsCount', checkers.length, args.length ]
    for checker, idx in checkers
      unless checker args[idx]
        return [ 'badArgument', idx, args[idx] ]
    return null

  # @private
  # @nodoc
  directAddToList : (listName, userNames) ->
    [
      check.string
      check.array.of.string
    ]

  # @private
  # @nodoc
  directGetAccessList : (listName) ->
    [
      check.string
    ]

  # @private
  # @nodoc
  directGetWhitelistMode : () ->
    []

  # @private
  # @nodoc
  directMessage : (toUser, msg) ->
    [
      check.string
      if @directMessagesChecker then @checkObject else @checkMessage
    ]

  # @private
  # @nodoc
  directRemoveFromList : (listName, userNames) ->
    [
      check.string
      check.array.of.string
    ]

  # @private
  # @nodoc
  directSetWhitelistMode : (mode) ->
    [
      check.boolean
    ]

  # @private
  # @nodoc
  disconnect : (reason) ->
    [
      check.string
    ]

  # @private
  # @nodoc
  listOwnSockets : () ->
    []

  # @private
  # @nodoc
  roomAddToList : (roomName, listName, userNames) ->
    [
      check.string
      check.string
      check.array.of.string
    ]

  # @private
  # @nodoc
  roomCreate : (roomName, mode) ->
    [
      check.string
      check.boolean
    ]

  # @private
  # @nodoc
  roomDelete : (roomName) ->
    [
      check.string
    ]

  # @private
  # @nodoc
  roomGetAccessList : (roomName, listName) ->
    [
      check.string
      check.string
    ]

  # @private
  # @nodoc
  roomGetOwner : (roomName) ->
    [
      check.string
    ]

  # @private
  # @nodoc
  roomGetWhitelistMode : (roomName) ->
    [
      check.string
    ]

  # @private
  # @nodoc
  roomHistory : (roomName)->
    [
      check.string
    ]

  # @private
  # @nodoc
  roomHistoryLastId : (roomName)->
    [
      check.string
    ]

  # @private
  # @nodoc
  roomHistorySync : (roomName, id)->
    [
      check.string
      (str) -> check.greaterOrEqual str, 0
    ]

  # @private
  # @nodoc
  roomJoin : (roomName) ->
    [
      check.string
    ]

  # @private
  # @nodoc
  roomLeave : (roomName) ->
    [
      check.string
    ]

  # @private
  # @nodoc
  roomMessage : (roomName, msg) ->
    [
      check.string
      if @roomMessagesChecker then @checkObject else @checkMessage
    ]

  # @private
  # @nodoc
  roomRemoveFromList : (roomName, listName, userNames) ->
    [
      check.string
      check.string
      check.array.of.string
    ]

  # @private
  # @nodoc
  roomSetWhitelistMode : (roomName, mode) ->
    [
      check.string
      check.boolean
    ]

  # @private
  # @nodoc
  systemMessage : (data) ->
    [
      -> true
    ]


module.exports = ArgumentsValidator