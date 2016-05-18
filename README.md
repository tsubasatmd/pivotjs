# pivotjs

pivotjs is a Javascript library which calculate pivot table data for multiple rows and columns with multiple measure.

## How to use
### Install
pivotjs is avaliable as npm library, so just call `npm install` command to install this.

```
npm install pivotjs[ --save]
```

### Prepare data
pivotjs manipulate Array typed data with Objects as following.

```
var records = [
  { category: 'A', data: 'a1', date: '2016-01-01', month: '2016-01', day: '01', value: 100},
  { category: 'A', data: 'a1', date: '2016-01-01', month: '2016-01', day: '01', value: 50},
  { category: 'A', data: 'a2', date: '2016-01-01', month: '2016-01', day: '01', value: 20},
  { category: 'B', data: 'b1', date: '2016-01-02', month: '2016-01', day: '02', value: 150},
  { category: 'B', data: 'b2', date: '2016-01-03', month: '2016-01', day: '03', value: 200},
  { category: 'C', data: 'c1', date: '2016-01-01', month: '2016-01', day: '01', value: 100},
  { category: 'C', data: 'c2', date: '2016-02-01', month: '2016-02', day: '01', value: 10}
]
```

### Params for pivot
#### measures
measure param is Array with measure objects which has key, format and aggregation attributes. pivotjs provides some aggregation function as following
```
sum
count
counta
unique
average
median
mode
max
min
```
Example for measure param is following.
```
var measures = [
  {
    key: 'value',
    name: 'SUM',
    format: 'int',
    aggregation: 'sum'
  },
  {
    key: 'value',
    name: 'AVERAGE',
    format: 'float',
    aggregation: 'average'
  }
];
```

#### Dimension(rows and cols)
Params for rows and cols are same object structure which has id(key) and sort attribute, but sort is object and has 2 types('self' and 'measure') like following.
For sort by self value (i.e.: using value A, B, C in this case)
```
var rows = [
  {
    id: 'category',
    sort: {
      type: 'self',
      ascending: true
    }
  }
];
```
Or for sort by measure value (i.e.: using value 170, 350, 10 in this case), key#sort is the columns key which is used by as sort value.
```
var rows = [
  {
    id: 'category',
    sort: {
      type: 'measure',
      key['2016-01']
      measureIndex: 0,
      ascending: false
    }
  }
];
```

If you want to populate pivot data with multiple rows, you just put another dimension object into rows array.

```
var rows = [
  {
    id: 'category',
    sort: {
      type: 'measure',
      measureIndex: 0,
      ascending: false
    }
  },
  {
    id: 'data',
    sort: {
      type: 'self',
      ascending: true
    }
  }
];
```

This is same for cols.
```
var cols = [
  {
    id: 'month',
    sort: {
      type: 'self',
      ascending: true
    }
  },
  {
    id: 'day',
    sort: {
      type: 'self',
      ascending: true
    }
  }
];
```

### Populate data
Just create Pivot class instance with argument object which has records, measures, rows, cols param object And call populate method.
```
var params = {
  records: records,
  measures: measures,
  rows: rows,
  cols: cols
};
var pivot = new Pivot(params);
pivot.populate();
```

### Get populated data
#### Get row keys and col keys
getSortedRowKeys(or getSortedColKeys)#pivot returns Each possible keys for rows or cols.
```
var rowKeys = pivot.getSortedRowKeys();
console.log(rowKeys);
-----
[['A', 'a1'], ['A', 'a2'], ['B', 'b1'], ['B', 'b2'], ['C', 'c1'],['C', 'c2']]
-----

var colKeys = pivot.getSortedColKeys();
console.log(colKeys);
-----
[['2016-01', '01'], ['2016-01', '02'], ['2016-01', '03'], ['2016-02', '01']]
-----
```
#### Get data
values(rowKey, colKey)#pivot returns Array of measures which has populated data for specified row and col key.
For example, if you want to get data for row:['A', 'a1'] and col:['2016-01', '01'] do like following.
```
var values = pivot.values(rowKeys[0], colKeys[0]);
console.log(values[0].value());
-----
150 // value for measure[0] i.e. summed value
-----

console.log(values[1].value());
-----
75 // value for measure[1] i.e. averaged value
-----
```

## Build
```
npm run build
```

## Test
```
npm run test
```
