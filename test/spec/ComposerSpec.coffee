'use strict'

describe 'Composer', ->
  should = chai.should()

  pivot = null
  colKey = []
  rowKey = []
  measure = {}
  composer = null

  beforeEach ->
    param = {}

    pivot = new Pivot param

    rowKey = ['key1']
    colKey = ['key2']
    composer = new Composer pivot, rowKey, colKey

  describe 'constructor', ->
    it 'default values of member should be set properly', ->
      composer.pivot.should.equal pivot
      composer.rowKey.should.equal rowKey
      composer.colKey.should.equal colKey
      composer.measureKeys.should.have.length 0
      composer.aggregators.should.have.length 0

  describe 'values', ->
    it 'value with measure should be returned properly', ->
      measure1 =
        name: 'masure1'
        key: 'key1'
        format: 'float'
        formatExpression: ',.2f'
        expression: 'exp1'
        aggregation: 'sum'
      record1 = {key1: 100, key2: 200}
      composer.add measure1, record1
      composer.add measure1, record1

      measure2 =
        name: 'masure2'
        key: 'key2'
        format: 'int'
        formatExpression: ',f'
        expression: 'exp2'
        aggregation: 'sum'
      record2 = {key1: 300, key2: 500}
      composer.add measure2, record2

      values = composer.values()

      values.should.have.length 2
      values[0].measure.should.equal 'key1'
      values[0].aggregation.should.equal 'sum'
      values[0].expression.should.equal 'exp1'
      values[0].format.should.equal 'float'
      values[0].formatExpression.should.equal ',.2f'
      values[0].value.should.equal 200
      values[1].measure.should.equal 'key2'
      values[1].aggregation.should.equal 'sum'
      values[1].expression.should.equal 'exp2'
      values[1].format.should.equal 'int'
      values[1].formatExpression.should.equal ',f'
      values[1].value.should.equal 500

  describe 'value', ->
    it 'self aggregator should be used when pos is null', ->
      measure =
        name: 'masure1'
        key: 'key1'
        format: 'float'
        aggregation: 'sum'
      record = {key1: 100, key2: 200}
      composer.add measure, record

      composer.value('key1', 'sum').should.equal 100

    it 'self aggregator should be used when pos is 0', ->
      measure =
        name: 'masure1'
        key: 'key1'
        format: 'float'
        aggregation: 'sum'
      record = {key1: 100, key2: 200}
      composer.add measure, record

      composer.value('key1', 'sum', 0).should.equal 100

    it 'pivot.getComposerWithGap should be called when pos is not 0', ->
      spy = sinon.spy pivot, 'getComposerWithGap'
      spy.withArgs rowKey, colKey, 1
      composer.value 'key1', 'sum', 1

      spy.calledOnce.should.be.true

      spy.restore()

  describe 'add', ->
    it 'measureKeys[Array] should be increased when adding new measure', ->
      measure =
        name: 'masure1'
        key: 'key1'
        format: 'float'
        aggregation: 'sum'
      record = {key1: 100, key2: 200}
      composer.add measure, record

      composer.measureKeys.should.have.length 1
      composer.measureKeys[0].should.equal pivot.serializeKey measure
      composer.aggregators.should.have.length 1
      composer.aggregators[0].aggregator.records.should.have.length 1

    it 'measureKeys[Array] is not changed and record count of aggregator should be changed when adding existing measure', ->
      measure =
        name: 'masure1'
        key: 'key1'
        format: 'float'
        aggregation: 'sum'
      record = {key1: 100, key2: 200}
      composer.add measure, record

      measure =
        name: 'masure1'
        key: 'key1'
        format: 'float'
        aggregation: 'sum'
      record = { key1: 200, key2: 300}
      composer.add measure, record

      composer.measureKeys.should.have.length 1
      composer.measureKeys[0].should.equal pivot.serializeKey measure
      composer.aggregators.should.have.length 1
      composer.aggregators[0].aggregator.records.should.have.length 2
