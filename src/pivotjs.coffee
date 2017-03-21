'use strict'

_ = if window?._ then window._ else require 'lodash'

class Pivot
  constructor: (@param) ->
    @formats =
      int: ',f'
      float: ',.2f'
      abbreviation: '2s'
      percent: '.2%'
    @defaultFormat = 'int'
    @defaultFormatExpression = @formats[@defaultFormat]

    @formatFunction = (val, format) -> val
    @aggregatorEvaluateFunction = (expression) -> null

    @records = @param.records or []
    @rowAttrs = @param.rows or []
    @colAttrs = @param.cols or []
    @measureAttrs = @param.measures or []
    _.each @measureAttrs, (measure) =>
      if _.has measure, 'format'
        measure.formatExpression =
          if measure.format is 'custom'
            measure.formatExpression
          else if _.has @formats, measure.format
            @formats[measure.format]
          else
            @defaultFormatExpression
      else
        measure.format = @defaultFormat
        measure.formatExpression = @defaultFormatExpression



    @rowKeys = []
    @colKeys = []
    @measureKeys = []
    @serializedRowKeys = []
    @serializedColKeys = []
    @sortedRowKeys = null
    @sortedColKeys = null

    @map = {}

    @grandTotal = new Composer @, [], []
    @rowTotals = {}
    @colTotals = {}


    @aggregationFunctions =
      sum: sum
      count: count
      counta: counta
      unique: unique
      average: average
      median: median
      mode: mode
      max: max
      min: min

  getNestedKeys: (dataset) ->
    return { children: [] } if dataset.length is 0 or !dataset

    root = {}
    node = null
    next = null

    _dataset = _.map dataset, (arr) ->
      _arr = JSON.parse JSON.stringify arr
      _arr.unshift 'root'
      _arr

    for path in _dataset
      node = root

      for _path in path
        node.children ||= {}

        next = node.children[_path]
        next ||= node.children[_path] =
          key: _path

        node = next

    root = _.values(root.children)[0]

    childrenToArray = (n, depth = 0) ->
      _.extend n,
        depth: depth

      if n.children
        _.extend n,
          children: _.values n.children
        _.each n.children, (child) ->
          childrenToArray child, (n.depth + 1)

    childrenToArray root

    root

  getRowKeys: ->
    @rowKeys

  getRowAttrs: ->
    @rowAttrs

  getSortedRowKeys: ->
    @sortedRowKeys ||= @getSortedKeys @rowKeys, @rowAttrs, 'row'

  getNestedRowKeys: ->
    @getNestedKeys @getSortedRowKeys()

  getColKeys: ->
    @colKeys

  getColAttrs: ->
    @colAttrs

  getSortedColKeys: ->
    @sortedColKeys ||= @getSortedKeys @colKeys, @colAttrs, 'col'

  getNestedColKeys: ->
    @getNestedKeys @getSortedColKeys()

  getMeasureAttrs: ->
    @measureAttrs

  getSortedKeys: (keys=[], attrs=[], sortKind=null) ->
    sort = (as, bs) -> # http://stackoverflow.com/a/4373421/112871
      rx = /(\d+)|(\D+)/g
      rd = /\d/
      rz = /^0/
      if typeof as is "number" or typeof bs is "number"
        return 1  if isNaN(as)
        return -1  if isNaN(bs)
        return as - bs
      a = String(as).toLowerCase()
      b = String(bs).toLowerCase()
      return 0  if a is b
      return (if a > b then 1 else -1) unless rd.test(a) and rd.test(b)
      a = a.match(rx)
      b = b.match(rx)
      while a.length and b.length
        a1 = a.shift()
        b1 = b.shift()
        if a1 isnt b1
          if rd.test(a1) and rd.test(b1)
            return a1.replace(rz, ".0") - b1.replace(rz, ".0")
          else
            return (if a1 > b1 then 1 else -1)
      a.length - b.length

    _.map keys, (key) ->
      _.extend [], key
    .sort (a, b) =>
      diff = 0
      return diff if (a.length isnt b.length)

      for value_a, index_a in a
        sortObject = attrs[index_a]?.sort
        type = sortObject?.type or null
        ascending = if sortObject.ascending is true then 1 else -1

        diff = switch type
          when 'self'
            b_value = b[index_a]
            sort(value_a, b_value) * ascending
          when 'measure'
            key_a = _.slice a, 0, (index_a + 1)
            key_b = _.slice b, 0, (index_a + 1)
            _key = sortObject.key
            pos = sortObject.measureIndex or 0

            [args_a, args_b] =
              if sortKind is 'row'
                [[key_a, _key], [key_b, _key]]
              else
                [[_key, key_a], [_key, key_b]]

            _value_a = @values.apply(@, args_a)?[pos]?.value or null
            _value_b = @values.apply(@, args_b)?[pos]?.value or null
            sort(_value_a, _value_b) * ascending
          else
            0
        break if diff isnt 0
      diff

  serializeKey: (keys) ->
    JSON.stringify keys

  deserializeKey: (sKey) ->
    JSON.parse sKey

  setFormatFunction: (func) ->
    @formatFunction = func

  setAggregatorEvaluateFunction: (func) ->
    @aggregatorEvaluateFunction = func

  populate: ->
    _.each @records, (record) =>
      @processRecord record

  processRecord: (record) =>
    rowKeys = (record[r.id] for r in @rowAttrs)
    colKeys = (record[c.id] for c in @colAttrs)

    serializedRowKey = @serializeKey rowKeys
    serializedColKey = @serializeKey colKeys

    serializedColKeysList = []
    for key, index in colKeys
      slicedColKeys = colKeys[0..index]
      serializedSlicedColKeys = @serializeKey slicedColKeys
      serializedColKeysList.push serializedSlicedColKeys

      if serializedColKey not in @serializedColKeys
        @colKeys.push colKeys
        @serializedColKeys.push serializedColKey

      unless @colTotals[serializedSlicedColKeys]
        @colTotals[serializedSlicedColKeys] = new Composer @, [], slicedColKeys

    serializedRowKeyList = []
    for key, index in rowKeys
      slicedRowKeys = rowKeys[0..index]
      serializedSlicedRowKeys = @serializeKey slicedRowKeys
      serializedRowKeyList.push serializedSlicedRowKeys

      if serializedRowKey not in @serializedRowKeys
        @rowKeys.push rowKeys
        @serializedRowKeys.push serializedRowKey

      unless @rowTotals[serializedSlicedRowKeys]
        @rowTotals[serializedSlicedRowKeys] = new Composer @, slicedRowKeys, []

      if colKeys.length isnt 0
        @map[serializedSlicedRowKeys] = {} if serializedSlicedRowKeys not of @map

        for cKey in serializedColKeysList
          if cKey not of @map[serializedSlicedRowKeys]
            cKeys = @deserializeKey cKey
            @map[serializedSlicedRowKeys][cKey] = new Composer @, slicedRowKeys, cKeys

    for measure in @measureAttrs
      @grandTotal.add measure, record

      colKeyList =
        if serializedColKeysList.length > 0
          serializedColKeysList
        else
          [serializedColKey]

      for ckey in colKeyList
        @colTotals[ckey]?.add measure, record

        for rkey in serializedRowKeyList
          @map[rkey]?[ckey]?.add measure, record

      for rkey in serializedRowKeyList
        @rowTotals[rkey]?.add measure, record

    return

  values: (rowKey, colKey) ->
    if rowKey.length isnt 0 and colKey.length isnt 0
      (@getComposer rowKey, colKey)?.values() or null
    else if rowKey.length is 0 and colKey.length is 0
      @grandTotal?.values() or null
    else if colKey.length is 0
      sKey = @serializeKey rowKey
      @rowTotals[sKey]?.values() or null
    else if rowKey.length is 0
      sKey = @serializeKey colKey
      @colTotals[sKey]?.values() or null

  getComposer: (rowKey, colKey) ->
    serializedRowKey = @serializeKey rowKey
    serializedColKey = @serializeKey colKey

    @map[serializedRowKey][serializedColKey]

  getComposerWithGap: (rowKey, colKey, gapIndex=0) ->
    index = -1
    for _colKey, _colIndex in @getSortedColKeys() when _.isEqual _colKey, colKey
      index = _colIndex
      break
    return null if index + gapIndex < 0

    index += gapIndex
    serializedRowKey = @serializeKey rowKey
    serializedColKey = @serializeKey @getSortedColKeys()[index]
    if @map[serializedRowKey]
      @map[serializedRowKey][serializedColKey] or null
    else
      @colTotals[serializedColKey] or null


  sum = (measureKey, aggregator) ->
    notEmptyRecords = _.filter aggregator.records, (record) ->
      !!record[measureKey] || record[measureKey] is 0
    return null if notEmptyRecords.length is 0

    _.reduce notEmptyRecords, (summed, record) ->
      summed + (parseFloat(record[measureKey]) or 0)
    , 0

  count = (measureKey, aggregator) ->
    aggregator.records.length or 0

  counta =  (measureKey, aggregator) ->
    cnt = 0
    for record in aggregator.records
      cnt++ unless record[measureKey] in [null, undefined]
    cnt

  unique =  (measureKey, aggregator) ->
    uniq = _.uniqBy aggregator.records, (record) ->
      record[measureKey]
    uniq.length

  average = (measureKey, aggregator) ->
    (sum(measureKey, aggregator) / counta(measureKey, aggregator)) or null

  max = (measureKey, aggregator) ->
    record = _.maxBy aggregator.records, (record) ->
      parseFloat(record[measureKey]) or 0
    record[measureKey] or null

  min = (measureKey, aggregator) ->
    notEmptyRecords = _.filter aggregator.records, (record) ->
      !!record[measureKey] || record[measureKey] is 0
    return null if notEmptyRecords.length is 0

    record = _.minBy notEmptyRecords, (record) ->
      parseFloat(record[measureKey]) or 0
    if record[measureKey] or record[measureKey] is 0 then record[measureKey] else null

  median = (measureKey, aggregator) ->
    records = _(aggregator.records).chain()
      .map (record) ->
        val = parseFloat(record[measureKey])
        val = if val.isNaN then null else val
      .compact()
      .value()
      .sort (a, b) ->
        a - b

    half = Math.floor records.length / 2
    if records.length % 2
      val = records[half]
    else
      val = (records[half-1] + records[half]) / 2

    val or null

  mode = (measureKey, aggregator) ->
    counter = {}
    modes = []
    max = 0

    records = aggregator.records
    for record in records
      val = record[measureKey]
      if val not of counter
        counter[val] = 0
      counter[val]++

      if counter[val] is max
        modes.push val
      else if counter[val] > max
        max = counter[val]
        modes = [val]
    modes


class Composer
  constructor: (pivot, rowKey, colKey) ->
    @pivot = pivot
    @rowKey = rowKey
    @colKey = colKey
    @measureKeys = []
    @aggregators = []

  values: ->
    _.map @aggregators, (agg) =>
      measure = @pivot.deserializeKey agg.measure

      measure: measure.key ? '-'
      aggregation: measure.aggregation
      expression: measure.expression
      format: measure.format
      formatExpression: measure.formatExpression
      value: if (agg.aggregator?.value() or agg.aggregator?.value() is 0) then agg.aggregator.value() else null

  value: (key, aggregation, pos=0) ->
    aggs =
      if pos in [0, null]
        @aggregators
      else
        @pivot.getComposerWithGap(@rowKey, @colKey, pos)?.aggregators or null
    aggs = aggs or []
    agg = _.find aggs, (agg) =>
      measure = @pivot.deserializeKey agg.measure
      measure.key is key and measure.aggregation is aggregation
    agg?.aggregator?.value() or null

  add: (measure, record) ->
    measureKey = @pivot.serializeKey measure
    if (_.indexOf @measureKeys, measureKey) < 0
      @measureKeys.push measureKey
      @aggregators.push
        measure: measureKey
        aggregator: new Aggregator @, measure

    agg = _.find @aggregators, (value) ->
      value.measure is measureKey
    agg.aggregator.push record


class Aggregator
  constructor: (composer, measure) ->
    @val = null
    @measure = measure
    @composer = composer
    @records = []
    @hasCache = false

  clearCache: ->
    @hasCache = false
    @val = null

  push: (record) ->
    @hasCache = false
    @records.push record

  value: ->
    return @val if @hasCache
    @hasCache = true
    if @measure.aggregation
      aggregatorFunction = @composer.pivot.aggregationFunctions[@measure.aggregation]
      @val = aggregatorFunction @measure.key, @
    else if @measure.expression
      try
        @val = @composer.pivot.aggregatorEvaluateFunction.apply this, [@measure.expression]
      catch e
        @val = null
    else
      @val = null

  formattedValue: ->
    _val =
      if @hasCache and @val isnt null
        @val
      else if @hasCache is false
        @value()
      else
        null
    return null if _val is null

    @composer.pivot.formatFunction _val, (@measure.formatExpression or @composer.pivot.defaultFormatExpression)


root = exports ? window
root.Pivot = Pivot
root.Composer = Composer
root.Aggregator = Aggregator
