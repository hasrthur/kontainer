# frozen_string_literal: true

module Fixtures
  class ClassWithOneKeywordDependency
    attr_reader :dependency

    def initialize(dependency:)
      @dependency = dependency
    end
  end
end
