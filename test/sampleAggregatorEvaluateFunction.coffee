# sample evaluate function using jsep expression parser
# ref: http://jsep.from.so/

sampleAggregatorEvaluateFunction = (expression) ->
  evaluate: (node) ->
    switch node.type
      when 'BinaryExpression'
        left = @evaluate(node.left)
        right = @evaluate(node.right)
        return null if left is null or right is null

        switch node.operator
          when '+' then left + right
          when '-' then left - right
          when '*' then left * right
          when '/'
            return null if right is 0
            left / right
          else throw new Error 'Unsupported Operator'
      when'MemberExpression'
        if node.type
          @composer.value node.object.name, node.property.name
        else
          throw new Error 'Unsupported Cascading MemberExpression'
      when 'UnaryExpression'
        return new Error 'Unsupported argument' if node.argument.type isnt 'Literal' and node.argument.type isnt 'MemberExpression'
        switch node.operator
          when '@'
            if node.argument.type is 'MemberExpression'
              if node.argument.object.type is 'Identifier'
                key = node.argument.object.name
                agg = node.argument.property.name
                pos = 0
              else if node.argument.object.type is 'MemberExpression'
                key = node.argument.object.object.name
                agg = node.argument.object.property.name
                pos = @evaluate node.argument.property
              else
                throw new Error ''
            @composer.value key, agg, pos
          when '-'
            -1 * node.argument.value
          when '+'
            node.argument.value
          else
            throw new Error 'Unsupported UnaryExpression'
      when 'Identifier'
        node.name
      when 'Literal'
        node.value
      else
        throw new Error 'Unsupported Expression'

  evaluate jsep expression
