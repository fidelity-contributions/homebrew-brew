# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for dynamic methods in `Homebrew::Cmd::Bundle`.
# Please instead update this file by running `bin/tapioca dsl Homebrew::Cmd::Bundle`.


class Homebrew::Cmd::Bundle
  sig { returns(Homebrew::Cmd::Bundle::Args) }
  def args; end
end

class Homebrew::Cmd::Bundle::Args < Homebrew::CLI::Args
  sig { returns(T::Boolean) }
  def all?; end

  sig { returns(T::Boolean) }
  def brews?; end

  sig { returns(T::Boolean) }
  def cask?; end

  sig { returns(T::Boolean) }
  def casks?; end

  sig { returns(T::Boolean) }
  def check?; end

  sig { returns(T::Boolean) }
  def cleanup?; end

  sig { returns(T::Boolean) }
  def describe?; end

  sig { returns(T::Boolean) }
  def f?; end

  sig { returns(T.nilable(String)) }
  def file; end

  sig { returns(T::Boolean) }
  def force?; end

  sig { returns(T::Boolean) }
  def formula?; end

  sig { returns(T::Boolean) }
  def global?; end

  sig { returns(T::Boolean) }
  def install?; end

  sig { returns(T::Boolean) }
  def mas?; end

  sig { returns(T::Boolean) }
  def no_restart?; end

  sig { returns(T::Boolean) }
  def no_upgrade?; end

  sig { returns(T::Boolean) }
  def no_vscode?; end

  sig { returns(T::Boolean) }
  def services?; end

  sig { returns(T::Boolean) }
  def tap?; end

  sig { returns(T::Boolean) }
  def taps?; end

  sig { returns(T::Boolean) }
  def upgrade?; end

  sig { returns(T::Boolean) }
  def vscode?; end

  sig { returns(T::Boolean) }
  def whalebrew?; end

  sig { returns(T::Boolean) }
  def zap?; end
end
