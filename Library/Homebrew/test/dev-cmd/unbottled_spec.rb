# typed: strict
# frozen_string_literal: true

require "cmd/shared_examples/args_parse"
require "dev-cmd/unbottled"

RSpec.describe Homebrew::DevCmd::Unbottled do
  it_behaves_like "parseable arguments"

  test_each_hash({ tahoe:         "doesn't support this macOS",
                   arm64_tahoe:   "ready to bottle",
                   aarch64_tahoe: "ready to bottle" }) do |tag, status|
    it "checks Xcode compatibility for the #{tag} target" do
      command = described_class.new(["--tag=#{tag}", "testball"])
      xcode_formula = formula("testball") do
        T.bind(self, T.class_of(Formula))
        url "https://brew.sh/testball-1.0.tgz"
        depends_on xcode: ["27.0", :build]
      end
      allow(command.args.named).to receive(:to_formulae).and_return([xcode_formula])

      expect { command.run }.to output(/testball: #{status}/).to_stdout
    end
  end

  it "prints that an unbottled formula with no dependencies is ready to bottle", :integration_test do
    setup_test_formula "testball"

    expect { brew "unbottled", "testball" }
      .to output(/testball: ready to bottle/).to_stdout
      .and not_to_output.to_stderr
      .and be_a_success
  end
end
