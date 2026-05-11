# frozen_string_literal: true

require_relative 'cbf_calendario/version'
require_relative 'cbf_calendario/client'
require_relative 'cbf_calendario/partida_stats'
require_relative 'cbf_calendario/urls'

module CbfCalendario
  module_function

  def parse_data_br!(str)
    Client.parse_data_br!(str)
  end

  # Atalho sem instanciar +Client+.
  def jogos_pendentes_no_dia(data, **client_options)
    Client.new(**client_options).jogos_pendentes_no_dia(data)
  end

  # GET /api/cbf/jogos/:id — Hash completo da API (chaves string).
  def partida_completa(id_jogo, **client_options)
    Client.new(**client_options).partida_completa(id_jogo)
  end

  # Somente o objeto +jogo+ do payload.
  def jogo_partida(id_jogo, **client_options)
    Client.new(**client_options).jogo_partida(id_jogo)
  end

  # Hash com todos os atletas do clube.
  def atletas_do_clube(id_clube, **client_options)
    Client.new(**client_options).atletas_do_clube(id_clube)
  end

  # Hash com os dados de um atleta específico.
  def atleta_por_id(id_atleta, **client_options)
    Client.new(**client_options).atleta_por_id(id_atleta)
  end

  # Hash com os dados de um clube específico.
  def clube_por_id(id_clube, **client_options)
    Client.new(**client_options).clube_por_id(id_clube)
  end

  # Estatísticas derivadas dos registros (+show_game.rb+).
  def estatisticas_agregadas(jogo)
    PartidaStats.agregadas(jogo)
  end
end
