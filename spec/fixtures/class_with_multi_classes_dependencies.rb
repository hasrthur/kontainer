# frozen_string_literal: true

module Fixtures
  class ClassWithMultiClassesDependencies
    attr_reader :dependencies

    def initialize(dependencies)
      @dependencies = dependencies
    end
  end
end
