# frozen_string_literal: true

require_relative '../test_helper'

module CbfCalendario
  class PartidaStatsTest < Minitest::Test
    def test_agregadas_counts_events_goals_cards_and_substitutions
      jogo = {
        'mandante' => { 'id' => 1, 'alteracoes' => [{}, {}] },
        'visitante' => { 'id' => 2, 'alteracoes' => [{}] },
        'registros' => [
          { 'tipo' => 'GOL', 'resultado' => 'NORMAL', 'clube_id' => 1 },
          { 'tipo' => 'GOL', 'resultado' => 'CONTRA', 'clube_id' => 2 },
          { 'tipo' => 'PENALIDADE', 'resultado' => 'AMARELO' },
          { 'tipo' => 'PENALIDADE', 'resultado' => 'VERMELHO' }
        ]
      }

      out = PartidaStats.agregadas(jogo)

      assert_equal 2, out[:por_tipo_evento]['GOL']
      assert_equal 2, out[:por_tipo_evento]['PENALIDADE']
      assert_equal 1, out[:gols_mandante_em_eventos]
      assert_equal 1, out[:gols_visitante_em_eventos]
      assert_equal 1, out[:cartoes_por_resultado]['AMARELO']
      assert_equal 1, out[:cartoes_por_resultado]['VERMELHO']
      assert_equal 2, out[:total_substituicoes_mandante]
      assert_equal 1, out[:total_substituicoes_visitante]
    end

    def test_agregadas_handles_missing_registros
      jogo = { 'mandante' => {}, 'visitante' => {}, 'registros' => nil }
      out = PartidaStats.agregadas(jogo)

      assert_equal({}, out[:por_tipo_evento])
      assert_equal 0, out[:gols_mandante_em_eventos]
      assert_equal 0, out[:gols_visitante_em_eventos]
    end
  end
end
