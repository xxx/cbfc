# frozen_string_literal: true

require_relative 'lib/cbfc/version'

Gem::Specification.new do |spec|
  spec.name          = 'cbfc'
  spec.version       = Cbfc::VERSION
  spec.authors       = ['mpd']
  spec.email         = ['mpd@jesters-court.net']

  spec.summary       = 'crappy brainfuck computer'
  spec.description   = 'A bad compiler to compile brainfuck to LLVM IR'
  spec.homepage      = 'https://github.com/xxx/cbfc'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'ffi'
  spec.add_runtime_dependency 'parslet'
  # spec.add_runtime_dependency 'ruby-llvm', '~> 10'
end
