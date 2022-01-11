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
  end
end
