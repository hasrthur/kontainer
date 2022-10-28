# frozen_string_literal: true

require "rbs"

require_relative "kontainer/version"

# Entrypoint module of IoC container
module Kontainer
  # Raised when the type is added to the container missing rbs signature
  class TypeWithoutSignatureError <     StandardError
    def initialize(type)
      super("'#{type}' can't be registered without .rbs file.")
    end
  end

  def self.new(&block)
    TypesRegistry.new.tap { |r| r.instance_exec(&block) }
  end

  # Deals with registration and resolving of services
  class TypesRegistry
    ENUMERABLE_TYPE = TypeName("Enumerable").absolute!
    private_constant :ENUMERABLE_TYPE

    ID = ->(x) { x }
    private_constant :ID

    def add_sigs(path)
      paths << path

      build_rbs
    end

    def add(type, as: type.to_s)
      ensure_rbs_loaded

      type = type.to_s
      as_type = as.to_s

      rbs_type = rbs_type_from(type)
      rbs_as_type = rbs_type_from(as_type)

      raise TypeWithoutSignatureError, type unless typed?(rbs_type)
      raise TypeWithoutSignatureError, as_type unless typed?(rbs_as_type)

      types_hash[as_type] << {
        type_to_build: Object.const_get(rbs_type.to_s),
        rbs_instance: @rbs_builder.build_instance(rbs_type)
      }
    end

    def resolve(type)
      resolve_by_limit(type) { _1.slice(-1, 1) }.first
    end

    def resolve_all(type)
      resolve_by_limit(type)
    end

    private

    def type_descriptors(type, &block)
      (block || ID).call(types_hash[type.to_s])
    end

    def resolve_by_limit(...)
      type_descriptors(...).map do |d|
        definition = d[:rbs_instance].methods[:initialize].defs.first
        d[:type_to_build].new(
          *positional_args_of(definition),
          **keyword_args_of(definition)
        )
      end
    end

    def positional_args_of(definition)
      definition
        .type # RBS::MethodType
        .type # RBS::Types::Function
        .required_positionals # [RBS::Types::Function::Param]
        .map { resolve_arg(_1.type) }
    end

    def keyword_args_of(definition)
      definition
        .type # RBS::MethodType
        .type # RBS::Types::Function
        .required_keywords # [[Symbol, RBS::Types::Function::Param]]
        .transform_values { resolve_arg(_1.type) }
    end

    def constantize_rbs_type(type)
      Object.const_get(type.name.to_s)
    end

    def resolve_arg(type)
      return resolve_all(type.args.first) if enumerable?(type)

      resolve(constantize_rbs_type(type))
    end

    def enumerable?(type)
      type.name == ENUMERABLE_TYPE
    end

    def rbs_type_from(type)
      *namespace, type_name = type.split("::")

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

    def typed?(rbs_type)
      !!(@rbs_environment.class_decls[rbs_type] || @rbs_environment.interface_decls[rbs_type])
    end

    def types_hash
      @types_hash ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def paths
      @paths ||= []
    end
  end

  private_constant :TypesRegistry
end
