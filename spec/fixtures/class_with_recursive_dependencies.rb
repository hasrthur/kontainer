# frozen_string_literal: true

module Fixtures
  class ClassWithRecursiveDependencies
    attr_reader :recursive_dependency, :simple_dependency, :dep_one

    def initialize(recursive_dependency, simple_dependency, dep_one:)
      @recursive_dependency = recursive_dependency
      @simple_dependency = simple_dependency
      @dep_one = dep_one
    end
  end
end
