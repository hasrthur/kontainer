# frozen_string_literal: true

require "rbs"

require_relative "kontainer/version"

# Entrypoint module of IoC container
module Kontainer
  # Raised when the type is added to the container missing rbs signature
  class TypeWithoutSignatureError < StandardError
    def initialize(type)
      super("'#{type}' can't be registered without .rbs file.")
    end
  end

  def self.new(&block)
    TypesRegistry.new.instance_exec(&block)
  end

  # Deals with registration and resolving of services
  class TypesRegistry
    def add_sigs(path)
      paths << path

      build_rbs
    end

    def add(type)
      ensure_rbs_loaded

      *namespace, type_name = type.to_s.split("::")

      rbs_type = RBS::TypeName.new(name: type_name.to_sym, namespace: Namespace(namespace.join("::")).absolute!)
      rbs_declaration = @rbs_environment.class_decls[rbs_type]

      raise TypeWithoutSignatureError, type if rbs_declaration.nil?
    end

    private

    def types_hash
      @types_hash ||= {}
    end

    def paths
      @paths ||= []
    end

    def ensure_rbs_loaded
      build_rbs if @rbs_builder.nil?
    end

    def build_rbs
      loader = RBS::EnvironmentLoader.new
      paths.each { |p| loader.add(path: Pathname(p)) }

      @rbs_environment = RBS::Environment.from_loader(loader).resolve_type_names
      @rbs_builder = RBS::DefinitionBuilder.new(env: @rbs_environment)
    end
  end

  private_constant :TypesRegistry
end
