export CvxConstr, ==, >=, <=, <, >

# TODO: Break down constraints.jl into multiple files- for equality/exponential,
# SOCP, SDP etc constraints

# TODO: CVX constraint should be an abstract class and children should be stuff
# like CVXEqualityConstr. Read:
# http://docs.julialang.org/en/release-0.2/manual/performance-tips/#break-functions-into-multiple-definitions

type CvxConstr
  head
  lhs
  rhs
  vexity
  size
  dual_value
  canon_form::Function
  function CvxConstr(head::Symbol, lhs::AbstractCvxExpr, rhs::AbstractCvxExpr)
    lhs, rhs = promote_for_add(lhs, rhs)

    # check vexity
    if head == :(==)
      if lhs.vexity in (:linear, :constant)  && rhs.vexity in (:linear, :constant)
        vexity = :linear
      else
        error("equality constraints between nonlinear expressions are not DCP compliant")
      end
    elseif head == :(<=)
      if lhs.vexity in (:linear, :constant, :convex) && rhs.vexity in (:linear, :constant, :concave)
        vexity = :convex
      else
        # error("constraint is not DCP compliant")
        # TODO: Figure it out
        vexity = :convex
      end
    elseif head == :(>=)
      error(">= should have been transformed to <=")
    else
      error("unrecognized comparison $head")
    end

    canon_form = ()->
      begin
        if lhs.vexity == :constant && rhs.vexity == :constant
          error ("TODO")

        elseif rhs.vexity == :constant
          constant = typeof(rhs.value) <: Number ? rhs.value : vec(rhs.value)
          canon_constr = {
            :coeffs => Any[speye(get_vectorized_size(lhs))],
            :vars => [unique_id(lhs)],
            :constant => constant,
            :is_eq => (head == :(==))
          }

          canon_constr_array = lhs.canon_form()
          push!(canon_constr_array, canon_constr)

        else
          canon_constr = {
            :coeffs => Any[speye(get_vectorized_size(lhs)), -speye(get_vectorized_size(rhs))],
            :vars => [unique_id(lhs); unique_id(rhs)],
            :constant => zeros(get_vectorized_size(lhs)),
            :is_eq => (head == :(==))
          }

          canon_constr_array = lhs.canon_form()
          append!(canon_constr_array, rhs.canon_form())
          push!(canon_constr_array, canon_constr)
        end
        return canon_constr_array
      end

    return new(head,lhs,rhs,vexity,size,nothing,canon_form)
  end
end

==(x::AbstractCvxExpr, y::AbstractCvxExpr) = CvxConstr(:(==), x, y)
>=(x::AbstractCvxExpr, y::AbstractCvxExpr) = CvxConstr(:(<=), y, x)
<=(x::AbstractCvxExpr, y::AbstractCvxExpr) = CvxConstr(:(<=), x, y)
>(x::AbstractCvxExpr, y::AbstractCvxExpr) = >=(x, y)
<(x::AbstractCvxExpr, y::AbstractCvxExpr) = <=(x, y)

==(x::Value, y::AbstractCvxExpr) = CvxConstr(:(==), y, convert(CvxExpr,x))
>=(x::Value, y::AbstractCvxExpr) = CvxConstr(:(<=), y, convert(CvxExpr,x))
<=(x::Value, y::AbstractCvxExpr) = CvxConstr(:(<=), -y, -convert(CvxExpr,x))
>(x::Value, y::AbstractCvxExpr) = <=(y, x)
<(x::Value, y::AbstractCvxExpr) = >=(y, x)

==(x::AbstractCvxExpr, y::Value)= CvxConstr(:(==), x, convert(CvxExpr,y))
>=(x::AbstractCvxExpr, y::Value) = CvxConstr(:(<=), -x, -convert(CvxExpr,y))
<=(x::AbstractCvxExpr, y::Value) = CvxConstr(:(<=), x, convert(CvxExpr,y))
>(x::AbstractCvxExpr, y::Value) = >=(x, y)
<(x::AbstractCvxExpr, y::Value) = <=(x, y)
