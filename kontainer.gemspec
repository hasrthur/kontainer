# frozen_string_literal: true

require_relative "lib/kontainer/version"

Gem::Specification.new do |spec|
  spec.name = "kontainer"
  spec.version = Kontainer::VERSION
  spec.authors = ["Artur Borysov"]
  spec.email = ["arthur.borisow@gmail.com"]

  spec.summary = "Ioc container for ruby 2.7+"
  spec.description = "Ioc container for ruby 2.7+"
  spec.homepage = "https://github.com/hasrthur/kontainer"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/hasrthur/kontainer"
  spec.metadata["changelog_uri"] = "https://github.com/hasrthur/kontainer/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rbs", "~> 2.7"

  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "rubocop-rspec", "~> 2.7"
  spec.add_development_dependency "steep", ">= 0.47.1"
end
