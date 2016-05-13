'use strict'

describe 'Aggregator', ->
  should = chai.should()

  pivot = null
  composer = null
  measure = null
  agg = null

  beforeEach ->
    param = {}

    pivot = new Pivot param

    composer = new Composer pivot, ['key1'], ['key2']

    measure =
      name: 'masure1'
      key: 'key1'
      format: 'float'
      aggregation: 'sum'

    agg = new Aggregator composer, measure

  describe 'constructor', ->
    it 'default values of member should be set properly', ->
      should.equal agg.val, null
      agg.measure.should.equal measure
      agg.composer.should.equal composer
      agg.records.should.have.length 0
      agg.hasCache.should.be.false

  describe 'clear cache', ->
    it 'has cache and value should be default value', ->
      agg.hasCache = true
      agg.val = 200

      agg.clearCache()

      agg.hasCache.should.be.false
      should.equal agg.val, null

  describe 'push', ->
    it 'count of records should be 1', ->
      agg.push
        col1: 1
        col2: 2

      agg.hasCache.should.be.false
      agg.records.should.have.length 1

  describe 'value', ->
    it 'cached value should be returned when hasCache', ->
      agg.hasCache = true
      agg.val = 200

      agg.value().should.equal 200

    it 'calculated value with aggregation function should be returned when measure has aggregation', ->
      agg.push
        key1: 150
        key2: 300
      agg.push
        key1: 100
        key2: 250
      agg.value().should.equal 250

    it 'calculated value with expression should be returned when measure does not have aggregation', ->
      param = {}
      pivot = new Pivot param
      pivot.setAggregatorEvaluateFunction aggregatorEvaluateFunction
      composer = new Composer pivot, ['key1'], ['key2']

      measure =
        name: 'masure2'
        key: 'key1'
        format: 'float'
        expression: 'a + b'

      agg = new Aggregator composer, measure

      agg.push
        key1: 150
        key2: 300
      agg.value().should.equal 'expression is a + b'

    it 'null should be returned when evaluate function throws error', ->
      param = {}
      pivot = new Pivot param
      pivot.setAggregatorEvaluateFunction aggregatorEvaluateFunctionWithError
      composer = new Composer pivot, ['key1'], ['key2']

      measure =
        name: 'masure2'
        key: 'key1'
        format: 'float'
        expression: 'a + b'

      agg = new Aggregator composer, measure

      agg.push
        key1: 150
        key2: 300
      should.equal agg.value(), null

  describe 'formattedValue', ->
    it 'val formatted with default format should be returned when hasCache and measure does not have formatExpression', ->
      pivot.setFormatFunction formatFunction

      agg.hasCache = true
      agg.val = 1000
      agg.formattedValue().should.equal '1,000'

    it 'val formatted with formatExpression should be returned', ->
      pivot.setFormatFunction formatFunction
      measure.formatExpression = ',.2f'

      agg.hasCache = true
      agg.val = 1000
      agg.formattedValue().should.equal '1,000.00'

    it 'value() should be called when hasCache is false', ->
      spy = sinon.spy agg, 'value'
      agg.hasCache = false
      agg.formattedValue()

      spy.calledOnce.should.be.true

      spy.restore()

    it 'pivot.formatFunction should not be called when value is null', ->
      spy = sinon.spy pivot, 'formatFunction'
      agg.hasCache = true
      agg.val = null

      should.equal agg.formattedValue(), null
      spy.callCount.should.equal 0

      spy.restore()

formatFunction = (val, formatExpression) ->
  d3.format(formatExpression) val


aggregatorEvaluateFunction = (expression) ->
  "expression is #{expression}"

aggregatorEvaluateFunctionWithError = (expression) ->
  throw new Error 'evaluate failed'
