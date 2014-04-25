export convert, promote_value, promote_rule, promote_for_add!, promote_for_mul!, promote_vexity, promote_sign, print_debug
export reverse_vexity, reverse_sign

### Conversion and promotion
# TODO: The difference between conversion and promotion is messy.
function convert(::Type{CvxExpr},x)
  if typeof(x) == CvxExpr
    return x
  else
    return Constant(x)
  end
end

# TODO: WTF is going on
promote_rule(::Type{CvxExpr}, ::Type{AbstractArray}) = CvxExpr
promote_rule(::Type{CvxExpr}, ::Type{Number}) = CvxExpr




### Utility functions for arithmetic
function promote_for_add!(x::Constant, sz::Int64)
  x.size = (sz, 1)
  x.value = x.value*ones(sz, 1)
end

function promote_for_add!(x::AbstractCvxExpr, sz::Int64)
  x = ones(sz)*x
end

function promote_for_add!(x::AbstractCvxExpr, y::AbstractCvxExpr)
  if x.size == y.size
    return
  elseif maximum(x.size) == 1
    promote_for_add!(x, y.size[1])
  elseif maximum(y.size) == 1
    promote_for_add!(y, x.size[1])
  else
    error("size of arguments cannot be added; got $(x.size),$(y.size)")
  end
end

function promote_for_mul!(x::Constant, sz::Int64)
  x.size = (sz, sz)
  x.value = x.value*speye(sz)
end

function promote_for_mul!(x::AbstractCvxExpr, sz::Int64)
  x = speye(sz)*x
end

function promote_for_mul!(x::AbstractCvxExpr, y::AbstractCvxExpr)
  if x.size[2] == y.size[1]
    return
  elseif maximum(x.size) == 1
    promote_for_mul!(x, y.size[1])
  elseif maximum(y.size) == 1
    promote_for_mul!(y, x.size[2])
  else
    error("size of arguments cannot be multiplied; got $(x.size),$(y.size)")
  end
end  

function promote_vexity(x::AbstractCvxExpr,y::AbstractCvxExpr)
  v1 = x.vexity; v2 = y.vexity; vexities = Set(v1,v2)
  if vexities == Set(:convex,:concave)
    error("expression not DCP compliant")
  elseif :convex in vexities
    return :convex
  elseif :concave in vexities
    return :concave
  elseif :linear in vexities
    return :linear
  else
    return :constant
  end
end

function promote_sign(x::AbstractCvxExpr,y::AbstractCvxExpr)
  s1 = x.sign; s2 = y.sign; signs = Set(s1,s2)
  if :any in signs || signs == Set(:pos,:neg)
    return :any
  else # then s1==s2
    return s1
  end
end

function promote_value(x::Value, sz::Int64)
  if size(x, 1) < sz
    return ones(sz, 1) * x
  end
  return x
end

function reverse_vexity(x::AbstractCvxExpr)
  vexity = x.vexity
  if vexity == :convex
    return :concave
  elseif vexity == :concave
    return :convex
  else
    return vexity
  end
end

function reverse_sign(x::AbstractCvxExpr)
  sign = x.sign
  if sign == :neg
    return :pos
  elseif sign == :pos
    return :neg
  else
    return sign
  end
end

function print_debug(debug, args...)
  if (debug)
    println(args)
  end
end