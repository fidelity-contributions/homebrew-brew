# typed: true
# frozen_string_literal: true

require "rubocops/class"

RSpec.describe RuboCop::Cop::FormulaAudit::TestResource do
  subject(:cop) { described_class.new }

  it "allows resources inside test blocks outside homebrew/core" do
    expect_no_offenses(<<~RUBY, "/Taps/example/homebrew-tools/Formula/foo.rb")
      class Foo < Formula
        url "https://brew.sh/foo-1.0.tar.gz"

        test do
          resource "fixture" do
            url "https://example.com/fixture.tar.gz"
          end
          resource("fixture").stage testpath
        end
      end
    RUBY
  end

  it "moves static test resources and their comments outside the test block" do
    expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
      class Foo < Formula
        url "https://brew.sh/foo-1.0.tar.gz"

        test do
          # Upstream fixture.
          resource "fixture" do
          ^^^^^^^^^^^^^^^^^^ FormulaAudit/TestResource: Declare test resources outside `test do` using `resource "name", :test do`.
            url "https://example.com/fixture.tar.gz"
            sha256 "abc"
          end

          resource("fixture").stage testpath
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class Foo < Formula
        url "https://brew.sh/foo-1.0.tar.gz"

        # Upstream fixture.
        resource "fixture", :test do
          url "https://example.com/fixture.tar.gz"
          sha256 "abc"
        end

        test do
          resource("fixture").stage testpath
        end
      end
    RUBY
  end

  it "moves multiple test resources without duplicating their test tags" do
    expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
      class Foo < Formula
        url "https://brew.sh/foo-1.0.tar.gz"

        test do
          resource "first", :test do
          ^^^^^^^^^^^^^^^^^^^^^^^ FormulaAudit/TestResource: Declare test resources outside `test do` using `resource "name", :test do`.
            url "https://example.com/first.tar.gz"
          end
          resource("second") do
          ^^^^^^^^^^^^^^^^^^ FormulaAudit/TestResource: Declare test resources outside `test do` using `resource "name", :test do`.
            url "https://example.com/second.tar.gz"
          end
          system "foo", "--version"
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class Foo < Formula
        url "https://brew.sh/foo-1.0.tar.gz"

        resource "first", :test do
          url "https://example.com/first.tar.gz"
        end

        resource("second", :test) do
          url "https://example.com/second.tar.gz"
        end

        test do
          system "foo", "--version"
        end
      end
    RUBY
  end

  it "reports resources using test-local values without autocorrecting them" do
    expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
      class Foo < Formula
        url "https://brew.sh/foo-1.0.tar.gz"

        test do
          fixture_url = "https://example.com/fixture.tar.gz"
          resource "fixture" do
          ^^^^^^^^^^^^^^^^^^ FormulaAudit/TestResource: Declare test resources outside `test do` using `resource "name", :test do`.
            url fixture_url
          end
          resource("fixture").stage testpath
        end
      end
    RUBY

    expect_no_corrections
  end

  it "reports conditional resources without making them unconditional" do
    expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
      class Foo < Formula
        url "https://brew.sh/foo-1.0.tar.gz"

        test do
          if OS.mac?
            resource "fixture" do
            ^^^^^^^^^^^^^^^^^^ FormulaAudit/TestResource: Declare test resources outside `test do` using `resource "name", :test do`.
              url "https://example.com/fixture.tar.gz"
            end
          end
          system "foo", "--version"
        end
      end
    RUBY

    expect_no_corrections
  end

  it "allows test resources declared outside the test block" do
    expect_no_offenses(<<~RUBY, "/homebrew-core/Formula/foo.rb")
      class Foo < Formula
        url "https://brew.sh/foo-1.0.tar.gz"

        resource "fixture", :test do
          url "https://example.com/fixture.tar.gz"
        end

        test do
          resource("fixture").stage do
            system "foo", "fixture"
          end
        end
      end
    RUBY
  end

  it "does not change heredoc contents when moving a resource" do
    expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
      class Foo < Formula
        url "https://brew.sh/foo-1.0.tar.gz"

        test do
          resource "fixture" do
          ^^^^^^^^^^^^^^^^^^ FormulaAudit/TestResource: Declare test resources outside `test do` using `resource "name", :test do`.
            url <<~URL
              https://example.com/fixture.tar.gz
            URL
          end
          resource("fixture").stage testpath
        end
      end
    RUBY

    expect_no_corrections
  end

  it "does not remove test code sharing a resource's closing line" do
    expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
      class Foo < Formula
        url "https://brew.sh/foo-1.0.tar.gz"

        test do
          resource "fixture" do
          ^^^^^^^^^^^^^^^^^^ FormulaAudit/TestResource: Declare test resources outside `test do` using `resource "name", :test do`.
            url "https://example.com/fixture.tar.gz"
          end; system "foo", "--version"
        end
      end
    RUBY

    expect_no_corrections
  end

  it "does not add test fixtures to a formula's bulk resource installation" do
    expect_offense(<<~RUBY, "/homebrew-core/Formula/foo.rb")
      class Foo < Formula
        url "https://brew.sh/foo-1.0.tar.gz"

        def install
          resources.each { |resource| resource.stage libexec }
        end

        test do
          resource "fixture" do
          ^^^^^^^^^^^^^^^^^^ FormulaAudit/TestResource: Declare test resources outside `test do` using `resource "name", :test do`.
            url "https://example.com/fixture.tar.gz"
          end
          resource("fixture").stage testpath
        end
      end
    RUBY

    expect_no_corrections
  end
end
