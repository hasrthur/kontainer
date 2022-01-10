# frozen_string_literal: true

RSpec.describe Kontainer do
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

  it "doesn't allow to add the same type twice"
end
