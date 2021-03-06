defmodule ShouldI.Matchers.Context do
  @moduledoc """
  Convenience macros for generating short test cases of common structure. These matchers work with the context.
  """

  import ExUnit.Assertions
  import ShouldI.Matcher

  @doc """
  Exactly match a key in the context to a value.

  ## Examples

      setup context do
        assign context, key_from_context_returned_by_setup: "exact expected value"
      end

      should_assign_key key_from_context_returned_by_setup: "exact expected value"
  """
  defmatcher should_assign_key([{key, value}]) do
    quote do
      assert var!(context)[unquote(key)] == unquote(value)
    end
  end

  @doc """
  Pattern match against `context[key]`

  ## Examples

      should_match_key context_key: {:ok, _}
  """
  defmatcher should_match_key([{key, expected}]) do
    {expected, binds} = interpolate(expected)
    quote do
      unquote(binds)
      assert unquote(expected) = var!(context)[unquote(key)]
    end
  end

  @doc """
  Check for existence of a key in the context returned by setup.

  ## Examples

      should_have_key :must_be_present
  """
  defmatcher should_have_key(key) do
    quote do
      assert Dict.has_key?(var!(context), unquote(key))
    end
  end

  @doc """
  Negative check for existence of a key in the context returned by setup.

  ## Examples

      should_not_have_key :must_not_be_present
  """
  defmatcher should_not_have_key(key) do
    quote do
      refute Dict.has_key?(var!(context), unquote(key))
    end
  end

  defp interpolate(ast) do
    {ast, binds} = interpolate(ast, [])

    binds = binds
         |> Enum.reverse
         |> Enum.map(fn {{_, meta, _} = var, expr} -> {:=, meta, [var, expr]} end)

    {ast, binds}
  end

  defp interpolate({:^, meta, [expr]}, binds) do
    var = {:"var#{length(binds)}", meta, __MODULE__}
    {{:^, meta, [var]}, [{var, expr}|binds]}
  end

  defp interpolate({func, meta, args}, binds) do
    {func, binds} = interpolate(func, binds)
    {args, binds} = interpolate(args, binds)
    {{func, meta, args}, binds}
  end

  defp interpolate({left, right}, binds) do
    {left, binds} = interpolate(left, binds)
    {right, binds} = interpolate(right, binds)
    {{left, right}, binds}
  end

  defp interpolate(list, binds) when is_list(list) do
    Enum.map_reduce(list, binds, &interpolate/2)
  end

  defp interpolate(ast, binds) do
    {ast, binds}
  end
end
