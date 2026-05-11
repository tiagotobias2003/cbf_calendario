# frozen_string_literal: true

require_relative '../test_helper'

module CbfCalendario
  class ClientTest < Minitest::Test
    def setup
      @client = Client.new
    end

    def test_parse_data_br_bang_parses_valid_date
      assert_equal Date.new(2026, 5, 11), Client.parse_data_br!('11/05/2026')
    end

    def test_parse_data_br_bang_raises_for_invalid_format
      assert_raises(InvalidDateError) { Client.parse_data_br!('2026-05-11') }
    end

    def test_parse_data_br_bang_raises_for_invalid_calendar_date
      assert_raises(InvalidDateError) { Client.parse_data_br!('31/02/2026') }
    end

    def test_coerce_date_bang_accepts_date_time_and_br_string
      assert_equal Date.new(2026, 5, 11), Client.coerce_date!(Date.new(2026, 5, 11))
      assert_equal Date.new(2026, 5, 11), Client.coerce_date!(Time.new(2026, 5, 11, 10, 0, 0))
      assert_equal Date.new(2026, 5, 11), Client.coerce_date!('11/05/2026')
    end

    def test_normalize_id_jogo_bang
      assert_equal '832031', Client.normalize_id_jogo!(' 832031 ')
      assert_raises(InvalidGameIdError) { Client.normalize_id_jogo!('abc') }
    end

    def test_calendario_json_calls_expected_path
      payload = { 'jogos' => {} }
      expected_path = '/api/cbf/calendario/jogos/2026/05/11'

      @client.stub(:get_json, lambda { |path|
        assert_equal expected_path, path
        payload
      }) do
        assert_equal payload, @client.calendario_json('11/05/2026')
      end
    end

    def test_jogos_do_dia_lists_all_games_including_placar
      payload = {
        'jogos' => {
          'Brasileiro' => {
            'Série A' => [
              {
                'id_jogo' => '2', 'hora' => '18:30', 'data' => '11/05/2026', 'local' => 'Mineirão', 'rodada' => '1',
                'mandante' => { 'nome' => 'Cruzeiro', 'gols' => nil },
                'visitante' => { 'nome' => 'Bahia', 'gols' => nil }
              },
              {
                'id_jogo' => '1', 'hora' => '16:00', 'data' => '11/05/2026', 'local' => 'Maracanã', 'rodada' => '1',
                'mandante' => { 'nome' => 'Flamengo', 'gols' => nil },
                'visitante' => { 'nome' => 'Santos', 'gols' => nil }
              },
              {
                'id_jogo' => '3', 'hora' => '20:00', 'data' => '11/05/2026', 'local' => 'Allianz', 'rodada' => '1',
                'mandante' => { 'nome' => 'Palmeiras', 'gols' => 1 },
                'visitante' => { 'nome' => 'SPFC', 'gols' => 0 }
              },
              {
                'id_jogo' => '1', 'hora' => '16:00', 'data' => '11/05/2026', 'local' => 'Maracanã', 'rodada' => '1',
                'mandante' => { 'nome' => 'Flamengo', 'gols' => nil },
                'visitante' => { 'nome' => 'Santos', 'gols' => nil }
              }
            ]
          }
        }
      }

      @client.stub(:get_json, payload) do
        result = @client.jogos_do_dia('11/05/2026')
        assert_equal 3, result.size
        assert_equal %w[1 2 3], result.map { |r| r[:id_jogo] }
        assert_equal '16:00', result.first[:horario]
        assert_nil result.first[:placar]
        jogo3 = result.find { |r| r[:id_jogo] == '3' }
        assert_equal '1 x 0', jogo3[:placar]
        assert_equal '20:00', jogo3[:horario]
      end
    end

    def test_partida_completa_returns_payload_when_jogo_present
      payload = { 'jogo' => { 'id_jogo' => 10 } }
      @client.stub(:get_json, payload) do
        assert_equal payload, @client.partida_completa('10')
      end
    end

    def test_partida_completa_raises_when_jogo_missing
      @client.stub(:get_json, { 'foo' => 'bar' }) do
        assert_raises(HttpError) { @client.partida_completa('10') }
      end
    end

    def test_jogo_partida_returns_only_jogo
      @client.stub(:partida_completa, { 'jogo' => { 'id_jogo' => 99 } }) do
        assert_equal({ 'id_jogo' => 99 }, @client.jogo_partida('99'))
      end
    end

  end
end
