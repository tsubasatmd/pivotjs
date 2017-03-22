'use strict'

describe 'Pivot', ->
  should = chai.should()

  pivot = null
  param = {}

  records = [
    {val: 100, cat: 'a', cat2: 'a1', date: '2016-01-01'}
    {val: 200, cat: 'a', cat2: 'a2', date: '2016-01-01'}
    {val: 100, cat: 'a', cat2: 'a2', date: '2016-01-01'}
    {val: 200, cat: 'a', cat2: 'a3', date: '2016-01-01'}
    {val: 400, cat: 'a', cat2: 'a2', date: '2016-01-02'}
    {val: 150, cat: 'a', cat2: 'a1', date: '2016-01-03'}
    {val: 300, cat: 'b', cat2: 'b1', date: '2016-01-02'}
    {val: 200, cat: 'c', cat2: 'c1', date: '2016-01-03'}
    {val: 1000, cat: 'd', cat2: 'd1', date: '2016-01-04'}
    {val: 0, cat: 'd', cat2: 'd1', date: '2016-01-04'}
    {val: null, cat: 'd', cat2: 'd1', date: '2016-01-04'}
    {val2: 100, val: null, cat: 'd', cat2: 'd1', date: '2016-01-05'}
  ]

  beforeEach ->
    param =
      records: records
      rows: [
        {
          id: 'cat'
          sort: {type: 'self', ascending: false}
        }
        {
          id: 'cat2'
          sort:
            type: 'measure'
            key: ['2016-01-01']
            measureIndex: 0
            ascending: true
        }
      ]
      cols: [
        {
          id: 'date'
          sort:
            type: 'measure'
            key: []
            measureIndex: 1
            ascending: true
        }
      ]
      measures: [
        {
          name: 'val'
          key: 'val'
          format: 'float'
          aggregation: 'sum'
        }
        {
          name: 'val'
          key: 'val'
          aggregation: 'average'
        }
        {
          name: 'val'
          key: 'val'
          format: 'custom'
          formatExpression: 'expression'
          aggregation: 'average'
        }
      ]
    pivot = new Pivot param

  describe 'constructor', ->
    it 'default values of member should be set properly', ->
      pivot.records.should.equal param.records
      pivot.rowAttrs.should.equal param.rows
      pivot.colAttrs.should.equal param.cols
      pivot.measureAttrs.should.equal param.measures

      pivot.rowKeys.should.have.length 0
      pivot.colKeys.should.have.length 0
      pivot.measureKeys.should.have.length 0
      pivot.serializedRowKeys.should.have.length 0
      pivot.serializedColKeys.should.have.length 0
      should.equal pivot.sortedRowKeys, null
      should.equal pivot.sortedColKeys, null
      pivot.map.should.be.empty
      pivot.grandTotal.should.be.instanceof Composer
      pivot.rowTotals.should.be.empty
      pivot.colTotals.should.be.empty

      pivot.measureAttrs[0].format.should.equal 'float'
      pivot.measureAttrs[0].formatExpression.should.equal ',.2f'
      pivot.measureAttrs[1].format.should.equal 'int'
      pivot.measureAttrs[1].formatExpression.should.equal ',f'

      pivot.measureAttrs[2].format.should.equal 'custom'
      pivot.measureAttrs[2].formatExpression.should.equal 'expression'

  describe 'getRowKeys', ->
    it 'should return rowsKey', ->
      pivot.populate()
      expect = [
        ['a', 'a1']
        ['a', 'a2']
        ['a', 'a3']
        ['b', 'b1']
        ['c', 'c1']
        ['d', 'd1']
      ]
      pivot.getRowKeys().should.eql expect

  describe 'getRowAttrs', ->
    it 'should return rows in param', ->
      pivot.populate()
      pivot.getRowAttrs().should.equal param.rows

  describe 'getSortedRowKeys', ->
    it 'should return rowsKey', ->
      pivot.populate()
      expect = [
        ['d', 'd1']
        ['c', 'c1']
        ['b', 'b1']
        ['a', 'a1']
        ['a', 'a3']
        ['a', 'a2']
      ]
      pivot.getSortedRowKeys().should.eql expect

  describe 'getNestedRowKeys', ->
    it 'should return nested object of row keys', ->
      pivot.populate()
      nestedObject = pivot.getNestedRowKeys()

      nestedObject.children.should.have.length 4

      nestedObject.children[0].key.should.equal 'd'
      nestedObject.children[0].children.should.have.length 1
      nestedObject.children[0].children[0].key.should.equal 'd1'
      should.equal nestedObject.children[0].children[0].children, undefined

      nestedObject.children[1].key.should.equal 'c'
      nestedObject.children[1].children.should.have.length 1
      nestedObject.children[1].children[0].key.should.equal 'c1'
      should.equal nestedObject.children[1].children[0].children, undefined

      nestedObject.children[2].key.should.equal 'b'
      nestedObject.children[2].children.should.have.length 1
      nestedObject.children[2].children[0].key.should.equal 'b1'
      should.equal nestedObject.children[2].children[0].children, undefined

      nestedObject.children[3].key.should.equal 'a'
      nestedObject.children[3].children.should.have.length 3
      nestedObject.children[3].children[0].key.should.equal 'a1'
      should.equal nestedObject.children[3].children[0].children, undefined
      nestedObject.children[3].children[1].key.should.equal 'a3'
      should.equal nestedObject.children[3].children[1].children, undefined
      nestedObject.children[3].children[2].key.should.equal 'a2'
      should.equal nestedObject.children[3].children[2].children, undefined

  describe 'getColKeys', ->
    it 'should return rowsKey', ->
      pivot.populate()
      expect = [
        ['2016-01-01']
        ['2016-01-02']
        ['2016-01-03']
        ['2016-01-04']
        ['2016-01-05']
      ]
      pivot.getColKeys().should.eql expect

  describe 'getColAttrs', ->
    it 'should return cols in param', ->
      pivot.populate()
      pivot.getColAttrs().should.equal param.cols

  describe 'getSortedColKeys', ->
    it 'should return rowsKey', ->
      pivot.populate()
      expect = [
        ['2016-01-05']
        ['2016-01-01']
        ['2016-01-03']
        ['2016-01-02']
        ['2016-01-04']
      ]
      pivot.getSortedColKeys().should.eql expect

  describe 'getNestedColKeys', ->
    it 'should return nested object of row keys', ->
      pivot.populate()
      nestedObject = pivot.getNestedColKeys()

      nestedObject.children.should.have.length 5

      nestedObject.children[0].key.should.equal '2016-01-05'
      should.equal nestedObject.children[0].children, undefined

      nestedObject.children[1].key.should.equal '2016-01-01'
      should.equal nestedObject.children[1].children, undefined

      nestedObject.children[2].key.should.equal '2016-01-03'
      should.equal nestedObject.children[2].children, undefined

      nestedObject.children[3].key.should.equal '2016-01-02'
      should.equal nestedObject.children[3].children, undefined
      
      nestedObject.children[4].key.should.equal '2016-01-04'
      should.equal nestedObject.children[4].children, undefined

  describe 'getMeasureAttrs', ->
    it 'should return measures in param', ->
      pivot.populate()
      pivot.getMeasureAttrs().should.equal param.measures

  # describe 'getSortedKeys', ->

  describe 'serializeKey', ->
    it 'should return serialized key', ->
      key = ['a', 'b']
      pivot.serializeKey(key).should.equal JSON.stringify key

  describe 'deserializeKey', ->
    it 'should return deserialized key', ->
      key = '["a", "b"]'
      pivot.deserializeKey(key).should.eql JSON.parse key

  describe 'setFormatFunction', ->
    it 'should be set function', ->
      func = -> 'test'
      pivot.setAggregatorEvaluateFunction func

      pivot.aggregatorEvaluateFunction.should.equal func

  describe 'setFormatFunction', ->
    it 'should be set function', ->
      func = -> 'test'
      pivot.setFormatFunction func

      pivot.formatFunction.should.equal func

  describe 'populate', ->
    it 'should call processRecord', ->
      spy = sinon.spy pivot, 'processRecord'

      pivot.populate()

      spy.callCount.should.equal records.length

      spy.restore()

  describe 'processRecord', ->
    it 'processRecord should add composer for correct keys to map', ->
      rowKey = pivot.serializeKey ['a']
      rowKey1 = pivot.serializeKey ['a', 'a1']
      rowKey2 = pivot.serializeKey ['a', 'a2']

      colKey1 = pivot.serializeKey ['2016-01-01']

      ### add new record ###
      pivot.processRecord records[0]

      # comporser for rowKey1 exist
      pivot.map[rowKey1].should.exist

      # rowTotal for ['a', 'a1'] exist and aggregator have 1 record
      pivot.rowTotals[rowKey1].should.exist
      pivot.rowTotals[rowKey1].aggregators.should.have.length 3
      pivot.rowTotals[rowKey1].aggregators[0].aggregator.records.should.have.length 1
      pivot.rowTotals[rowKey1].aggregators[1].aggregator.records.should.have.length 1

      # rowTotal for ['a'] exist and aggregator have 1 record
      pivot.rowTotals[rowKey].should.exist
      pivot.rowTotals[rowKey].aggregators.should.have.length 3
      pivot.rowTotals[rowKey].aggregators[0].aggregator.records.should.have.length 1
      pivot.rowTotals[rowKey].aggregators[1].aggregator.records.should.have.length 1

      pivot.colTotals[colKey1].should.exist
      pivot.colTotals[colKey1].aggregators.should.have.length 3
      pivot.colTotals[colKey1].aggregators[0].aggregator.records.should.have.length 1
      pivot.colTotals[colKey1].aggregators[1].aggregator.records.should.have.length 1

      # each aggregator for grandTotal composer have 1 record
      pivot.grandTotal.aggregators.should.have.length 3
      pivot.grandTotal.aggregators[0].aggregator.records.should.have.length 1
      pivot.grandTotal.aggregators[1].aggregator.records.should.have.length 1

      # composer for rowKey2 is not exist
      should.equal pivot.map[rowKey2], undefined
      should.equal pivot.rowTotals[rowKey2], undefined


      ### add new record ###
      pivot.processRecord records[1]

      # comporser for rowKey2 exist
      pivot.map[rowKey2].should.exist

      # rowTotal for ['a', 'a2'] exist and aggregator have 1 record
      pivot.rowTotals[rowKey2].should.exist
      pivot.rowTotals[rowKey2].aggregators.should.have.length 3
      pivot.rowTotals[rowKey2].aggregators[0].aggregator.records.should.have.length 1
      pivot.rowTotals[rowKey2].aggregators[1].aggregator.records.should.have.length 1

      # aggregator for rowTotal for ['a'] have 2 record (plus 1)
      pivot.rowTotals[rowKey].aggregators.should.have.length 3
      pivot.rowTotals[rowKey].aggregators[0].aggregator.records.should.have.length 2
      pivot.rowTotals[rowKey].aggregators[1].aggregator.records.should.have.length 2

      # records of aggregator for rowTotals['a', 'a1'] is not changed
      pivot.rowTotals[rowKey1].aggregators.should.have.length 3
      pivot.rowTotals[rowKey1].aggregators[0].aggregator.records.should.have.length 1
      pivot.rowTotals[rowKey1].aggregators[1].aggregator.records.should.have.length 1

      # aggregator for colTotals['2016-01-01'] have 2 records (plus 1)
      pivot.colTotals[colKey1].should.exist
      pivot.colTotals[colKey1].aggregators.should.have.length 3
      pivot.colTotals[colKey1].aggregators[0].aggregator.records.should.have.length 2
      pivot.colTotals[colKey1].aggregators[1].aggregator.records.should.have.length 2

      # record count of aggregator for grandtoral is 2 (plus 1)
      pivot.grandTotal.aggregators.should.have.length 3
      pivot.grandTotal.aggregators[0].aggregator.records.should.have.length 2
      pivot.grandTotal.aggregators[1].aggregator.records.should.have.length 2

  describe 'values', ->
    spy = null

    beforeEach -> pivot.populate()

    afterEach -> spy.restore()

    it 'should call value method of correct composer when both row, col exist', ->
      rowKey = ['a', 'a1']
      colKey = ['2016-01-01']

      composer = pivot.map[pivot.serializeKey rowKey][pivot.serializeKey colKey]
      spy = sinon.spy composer, 'values'

      values = pivot.values rowKey, colKey

      values[0].value.should.equal 100
      values[1].value.should.equal 100
      values[2].value.should.equal 100

      spy.calledOnce.should.be.true

    it 'should call value method of grandTotal composer when both row, col length is 0', ->
      composer = pivot.grandTotal
      spy = sinon.spy composer, 'values'

      values = pivot.values [], []

      values[0].value.should.equal 2650
      values[1].value.should.equal 265
      values[2].value.should.equal 265

      spy.calledOnce.should.be.true

    it 'should call value method of rowTotal composer when col length is 0', ->
      rowKey = ['a', 'a1']
      colKey = []

      composer = pivot.rowTotals[pivot.serializeKey rowKey]
      spy = sinon.spy composer, 'values'

      values = pivot.values rowKey, colKey

      values[0].value.should.equal 250
      values[1].value.should.equal 125
      values[2].value.should.equal 125

      spy.calledOnce.should.be.true

    it 'should call value method of colTotal composer when row length is 0', ->
      rowKey = []
      colKey = ['2016-01-01']

      composer = pivot.colTotals[pivot.serializeKey colKey]
      spy = sinon.spy composer, 'values'

      values = pivot.values rowKey, colKey

      values[0].value.should.equal 600
      values[1].value.should.equal 150
      values[2].value.should.equal 150

      spy.calledOnce.should.be.true

  describe 'getComposer', ->
    it 'should return composer with same rowKey and colKey', ->
      pivot.populate()
      agg = pivot.getComposer ['a', 'a2'], ['2016-01-01']

      agg.rowKey.should.eql ['a', 'a2']
      agg.colKey.should.eql ['2016-01-01']

  describe 'getComposerWithGap', ->
    beforeEach -> pivot.populate()

    it 'should return composer with same colKey when without gap', ->
      agg = pivot.getComposerWithGap ['a', 'a2'], ['2016-01-02']

      agg.rowKey.should.eql ['a', 'a2']
      agg.colKey.should.eql ['2016-01-02']

    it 'should return null if colkey is the last key', ->
      agg = pivot.getComposerWithGap ['a', 'a2'], ['2016-01-02'], 1

      should.equal agg, null

    it 'should return composer with same next colKey when gap is -2', ->
      agg = pivot.getComposerWithGap ['a', 'a2'], ['2016-01-02'], -2

      agg.rowKey.should.eql ['a', 'a2']
      agg.colKey.should.eql ['2016-01-01']

    it 'should return col-total composer when rowkey is not exist in rowkeys list', ->
      agg = pivot.getComposerWithGap null, ['2016-01-02'], -2

      agg.rowKey.should.eql []
      agg.colKey.should.eql ['2016-01-01']

  describe 'sum', ->
    it 'should return summed value', ->
      agg =
        records: records
      pivot.aggregationFunctions['sum']('val', agg).should.equal 2650

    it 'should return null if no value', ->
      agg =
        records: records
      should.equal(pivot.aggregationFunctions['sum']('val3', agg), null)

  describe 'count', ->
    it 'should return record count', ->
      agg =
        records: records
      pivot.aggregationFunctions['count']('val', agg).should.equal 12

  describe 'counta', ->
    it 'should return record count which value is null or undefined', ->
      agg =
        records: records
      pivot.aggregationFunctions['counta']('val', agg).should.equal 10

  describe 'unique', ->
    it 'should return unique record count', ->
      agg =
        records: records
      pivot.aggregationFunctions['unique']('cat', agg).should.equal 4

  describe 'average', ->
    it 'should return average of non-null values', ->
      agg =
        records: records
      pivot.aggregationFunctions['average']('val', agg).should.equal 265

    it 'should return null when denominator is 0', ->
      agg =
        records: records
      should.equal(pivot.aggregationFunctions['average']('val1', agg), null)

  describe 'max', ->
    it 'should return max value', ->
      agg =
        records: records
      pivot.aggregationFunctions['max']('val', agg).should.equal 1000

  describe 'min', ->
    it 'should return min value ignoring null', ->
      agg =
        records: records
      pivot.aggregationFunctions['min']('val', agg).should.equal 0

    it 'should return min value ignoring undefined', ->
      agg =
        records: records
      pivot.aggregationFunctions['min']('val2', agg).should.equal 100

    it 'should return null if no values', ->
      agg =
        records: records
      should.equal(pivot.aggregationFunctions['min']('val3', agg), null)

  describe 'median', ->
    it 'should return median value', ->
      agg =
        records: records
      pivot.aggregationFunctions['median']('val', agg).should.equal 200

  describe 'mode', ->
    it 'should return mode value', ->
      agg =
        records: records
      pivot.aggregationFunctions['mode']('val', agg).should.eql [200]
