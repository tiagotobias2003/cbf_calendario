# frozen_string_literal: true

require_relative 'lib/cbf_calendario/version'

Gem::Specification.new do |spec|
  spec.name          = 'cbf_calendario'
  spec.version       = CbfCalendario::VERSION
  spec.authors       = ['Betbrothers']
  spec.summary       = 'Cliente Ruby para o calendário de jogos da CBF (hashes, uso em Rails)'
  spec.description   = <<~DESC
    Consulta a API pública de calendário da CBF e devolve jogos pendentes (sem placar)
    para uma data, como Array de hashes Ruby — adequado para uso em Ruby on Rails.
  DESC
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.homepage = 'https://github.com/betbrothers/cbf_calendario'
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['documentation_uri'] = 'https://rubydoc.info/gems/cbf_calendario'

  spec.files = Dir.chdir(__dir__) do
    %w[LICENSE.txt README.md CHANGELOG.md cbf_calendario.gemspec] + Dir['lib/**/*.rb']
  end
  spec.require_paths = ['lib']
end
