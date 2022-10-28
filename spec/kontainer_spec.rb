# frozen_string_literal: true

RSpec.describe Kontainer do
  describe "adding" do
    it "does not support classes without signatures" do
      expect do
        Kontainer.new do
          add Fixtures::ClassWithoutSig
        end
      end.to raise_error(
        Kontainer::TypeWithoutSignatureError,
        "'#{Fixtures::ClassWithoutSig}' can't be registered without .rbs file."
      )
    end

    it "supports classes with signatures" do
      expect do
        Kontainer.new do
          add_sigs "spec/fixtures/sig"

          add Fixtures::ClassWithSig
        end
      end.to_not raise_error
    end

    it "doesn't add classes which have overloaded initializers"
    it "doesn't add classes which have optional keywords in initializer"
    it "doesn't add classes which have optional positionals in initializer"
    it "doesn't add classes which have block in initializer"
    it "doesn't add classes which depend on themselves"
    it "doesn't add classes identified by classes if the former doesn't inherit from the latter"
    it "doesn't add class identified by interface if it doesn't conform to that interface"
    it "doesn't add interface identified by interface"
  end

  describe "validate" do
    it "raises when there are types which depend on types which has never been added to kontainer"
    it "raises when there are types which create circular dependency on other types"
  end

  describe "resolving" do
    let(:kontainer) do
      Kontainer.new do
        add_sigs "spec/fixtures/sig"

        add Fixtures::ClassWithSig
        add Fixtures::ClassWithOnePositionalDependency
        add Fixtures::ClassWithOneKeywordDependency
        add Fixtures::ClassWithRecursiveDependencies

        add Fixtures::ClassWithInterface, as: "::Fixtures::_SimpleInterface"

        add Fixtures::MultiClassOne, as: "::Fixtures::_MultiInterface"
        add Fixtures::MultiClassTwo, as: "::Fixtures::_MultiInterface"
        add Fixtures::ClassWithMultiClassesDependencies
      end
    end

    it "resolves added types" do
      expect(kontainer.resolve(Fixtures::ClassWithSig)).to be_an Fixtures::ClassWithSig
    end

    it "resolves added types with their dependencies as required positionals" do
      object = kontainer.resolve(Fixtures::ClassWithOnePositionalDependency)

      expect(object.dependency).to be_an Fixtures::ClassWithSig
    end

    it "resolves added types with their dependencies as required keywords" do
      object = kontainer.resolve(Fixtures::ClassWithOneKeywordDependency)

      expect(object.dependency).to be_an Fixtures::ClassWithSig
    end

    it "resolves added types and their dependencies recursively" do
      object = kontainer.resolve(Fixtures::ClassWithRecursiveDependencies)

      expect(object.recursive_dependency).to be_an Fixtures::ClassWithOneKeywordDependency
      expect(object.recursive_dependency.dependency).to be_an Fixtures::ClassWithSig

      expect(object.simple_dependency).to be_an Fixtures::ClassWithSig

      expect(object.dep_one).to be_an Fixtures::ClassWithOnePositionalDependency
      expect(object.dep_one.dependency).to be_an Fixtures::ClassWithSig
    end

    it "resolves added types by interface" do
      object = kontainer.resolve("::Fixtures::_SimpleInterface")

      expect(object).to be_an Fixtures::ClassWithInterface
      expect(object.call).to eq 42
    end

    it "resolves enumerable of added services" do
      object = kontainer.resolve(Fixtures::ClassWithMultiClassesDependencies)

      expect(object.dependencies.count).to eq 2

      expect(object.dependencies.first).to be_an Fixtures::MultiClassOne
      expect(object.dependencies.first.call_again).to eq 17

      expect(object.dependencies.last).to be_an Fixtures::MultiClassTwo
      expect(object.dependencies.last.call_again).to eq 44
    end

    it "resolves array of added services"
  end
end
