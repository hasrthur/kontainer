# frozen_string_literal: true

require "rbs"

require_relative "kontainer/version"

# Entrypoint module of IoC container
module Kontainer
  # Raised when the type is added to the container missing rbs signature
  class TypeWithoutSignatureError <  StandardError
    def initialize(type)
      super("'#{type}' can't be registered without .rbs file.")
    end
  end

  def self.new(&block)
    TypesRegistry.new.tap { |r| r.instance_exec(&block) }
  end

  # Deals with registration and resolving of services
  class TypesRegistry
    def add_sigs(path)
      paths << path

      build_rbs
    end

    def add(type)
      ensure_rbs_loaded

      rbs_type = rbs_type_from(type)
      raise TypeWithoutSignatureError, type if @rbs_environment.class_decls[rbs_type].nil?

      types_hash[type] = @rbs_builder.build_instance(rbs_type)
    end

    def resolve(type)
      definition = types_hash[type].methods[:initialize].defs.first

      type.new(
        *positional_args_of(definition),
        **keyword_args_of(definition)
      )
    end

    private

    def positional_args_of(definition)
      definition
        .type # RBS::MethodType
        .type # RBS::Types::Function
        .required_positionals # [RBS::Types::Function::Param]
        .map(&method(:resolve_arg))
    end

    def keyword_args_of(definition)
      definition
        .type # RBS::MethodType
        .type # RBS::Types::Function
        .required_keywords # [[Symbol, RBS::Types::Function::Param]]
        .transform_values(&method(:resolve_arg))
    end

    def constantize_rbs_type(type)
      Object.const_get(type.type.name.to_s)
    end

    def resolve_arg(type)
      resolve(constantize_rbs_type(type))
    end

    def rbs_type_from(type)
      *namespace, type_name = type.to_s.split("::")

      RBS::TypeName.new(name: type_name.to_sym, namespace: Namespace(namespace.join("::")).absolute!)
    end

    def ensure_rbs_loaded
      build_rbs if @rbs_builder.nil?
    end

    def build_rbs
      loader = RBS::EnvironmentLoader.new.tap do |l|
        paths.each { |p| l.add(path: Pathname(p)) }
      end

      @rbs_environment = RBS::Environment.from_loader(loader).resolve_type_names
      @rbs_builder = RBS::DefinitionBuilder.new(env: @rbs_environment)
    end

    def types_hash
      @types_hash ||= {}
    end

    def paths
      @paths ||= []
    end
  end
  private_constant :TypesRegistry
end
