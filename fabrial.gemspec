# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fabrial/version'

Gem::Specification.new do |spec|
  spec.name          = 'fabrial'
  spec.version       = Fabrial::VERSION
  spec.authors       = ['Jeremy Mickelson', 'Tad Thorley']
  spec.email         = ['jeremy.mickelson@gmail.com']

  spec.summary       = 'Simply create test data inline with your tests'
  spec.description   = <<~DESCRIPTION
    Fabrial makes it easy to follow the "Arrange, Act, Assert" pattern in your tests.
    It makes it trivial to create your test data directly inline with your tests;
    removing the need for hard-to-maintain fixture files or blueprints.
  DESCRIPTION

  spec.homepage      = 'https://github.com/allydvm/fabrial'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the
  # 'allowed_push_host' to allow pushing to a single host or delete this section to allow
  # pushing to any host.
  # if spec.respond_to?(:metadata)
  #   spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  # else
  #   raise "RubyGems 2.0 or newer is required to protect against " \
  #     "public gem pushes."
  # end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3.0'

  spec.add_development_dependency 'appraisal', '~> 2.2', '>= 2.2.0'
  spec.add_development_dependency 'bundler', '~> 1.0'
  spec.add_development_dependency 'minitest', '~> 5.12', '>= 5.12.2'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 0.75.0'
end
