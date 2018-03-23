
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ncurses/lyra/version"

Gem::Specification.new do |spec|
  spec.name          = "ncurses-lyra"
  spec.version       = Ncurses::Lyra::VERSION
  spec.authors       = ["kepler"]
  spec.email         = ["githubkepler.50s@gishpuppy.com"]

  spec.summary       = %q{a small fast minimal file lister and explorer}
  spec.description   = %q{a light fast directory explorer in ncurses}
  spec.homepage      = "https://github.com/mare-imbrium/ncurses-lyra"
  spec.license       = "MIT"


  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency "ffi-ncurses", ">= 0.4.0", ">= 0.4.0"
end
