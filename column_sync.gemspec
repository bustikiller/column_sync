# frozen_string_literal: true

require_relative "lib/column_sync/version"

Gem::Specification.new do |spec|
  spec.name = "column_sync"
  spec.version = ColumnSync::VERSION
  spec.authors = ["Manuel Bustillo"]
  spec.email = ["bustikiller@bustikiller.com"]

  spec.summary = "A ruby gem to sync values between columns using Postgres and Rails"
  spec.homepage = "https://github.com/bustikiller/column_sync"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bustikiller/column_sync"
  spec.metadata["changelog_uri"] = "https://github.com/bustikiller/column_sync/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "fx", "~> 0.8.0"
  spec.add_runtime_dependency "pg", "~> 1.5.4"
  spec.add_runtime_dependency "rails", ">= 6.0.0"
  spec.add_development_dependency "rubocop"
end
