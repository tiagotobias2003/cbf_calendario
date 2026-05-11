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

    def test_normalize_id_clube_bang
      assert_equal '20001', Client.normalize_id_clube!('20001')
      assert_raises(InvalidClubIdError) { Client.normalize_id_clube!('20A01') }
    end

    def test_normalize_id_atleta_bang
      assert_equal '12345', Client.normalize_id_atleta!('12345')
      assert_raises(InvalidAthleteIdError) { Client.normalize_id_atleta!('xpto') }
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

    def test_jogos_pendentes_no_dia_filters_and_maps_horario
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
        result = @client.jogos_pendentes_no_dia('11/05/2026')
        assert_equal 2, result.size
        assert_equal %w[1 2], result.map { |r| r[:id_jogo] }
        assert_equal '16:00', result.first[:horario]
        refute result.first.key?(:placar_ou_horario)
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

    def test_atletas_do_clube_accepts_array_payload
      payload = [{ 'id_atleta' => 1 }]
      @client.stub(:get_json, payload) do
        assert_equal({ clube_id: '20001', atletas: payload }, @client.atletas_do_clube('20001'))
      end
    end

    def test_atletas_do_clube_accepts_hash_with_atletas
      payload = { 'atletas' => [{ 'id_atleta' => 1 }] }
      @client.stub(:get_json, payload) do
        assert_equal({ clube_id: '20001', atletas: payload['atletas'] }, @client.atletas_do_clube('20001'))
      end
    end

    def test_atletas_do_clube_raises_on_invalid_payload
      @client.stub(:get_json, { 'foo' => [] }) do
        assert_raises(HttpError) { @client.atletas_do_clube('20001') }
      end
    end

    def test_atleta_por_id_success_from_hash_payload
      @client.stub(:buscar_atleta_payload, { 'id_atleta' => '10', 'nome' => 'Teste' }) do
        out = @client.atleta_por_id('10')
        assert_equal '10', out[:atleta_id]
        assert_equal 'Teste', out[:atleta]['nome']
      end
    end

    def test_atleta_por_id_success_from_array_payload
      payload = [{ 'id_atleta' => '10', 'nome' => 'Atleta 10' }, { 'id_atleta' => '11', 'nome' => 'Outro' }]
      @client.stub(:buscar_atleta_payload, payload) do
        out = @client.atleta_por_id('10')
        assert_equal 'Atleta 10', out[:atleta]['nome']
      end
    end

    def test_clube_por_id_success_from_api_payload
      payload = { 'id_clube' => '20001', 'nome' => 'Corinthians' }
      @client.stub(:buscar_clube_payload, payload) do
        out = @client.clube_por_id('20001')
        assert_equal '20001', out[:clube_id]
        assert_equal 'Corinthians', out[:clube]['nome']
      end
    end

    def test_clube_por_id_uses_scraping_fallback_when_api_fails
      scraped = { 'id_clube' => 20001, 'nome' => 'Corinthians - SP', 'atletas' => [] }
      @client.stub(:buscar_clube_payload, ->(_id) { raise HttpError, '404' }) do
        @client.stub(:buscar_clube_por_scraping, scraped) do
          out = @client.clube_por_id('20001')
          assert_equal 'Corinthians - SP', out[:clube]['nome']
        end
      end
    end

    def test_clube_por_id_raises_when_api_and_fallback_fail
      @client.stub(:buscar_clube_payload, ->(_id) { raise HttpError, '404' }) do
        @client.stub(:buscar_clube_por_scraping, {}) do
          assert_raises(HttpError) { @client.clube_por_id('20001') }
        end
      end
    end

    def test_busca_clube_por_scraping_extracts_data_from_public_pages
      list_html = <<~HTML
        <a href="/futebol-brasileiro/times/campeonato-brasileiro/serie-a/2026/20001">Corinthians</a>
      HTML
      detail_html = <<~HTML
        <h1>Corinthians - SP</h1>
        <table>
          <tr><th>Nome</th><th>Apelido</th><th>Clube Atual</th></tr>
          <tr><td>Nome Um</td><td>N1</td><td>Corinthians</td></tr>
          <tr><td>Nome Dois</td><td>N2</td><td>Corinthians</td></tr>
        </table>
      HTML

      @client.stub(:request_text, ->(uri) { uri.path == '/futebol-brasileiro/times' ? list_html : detail_html }) do
        out = @client.send(:buscar_clube_por_scraping, '20001')
        assert_equal 20001, out['id_clube']
        assert_equal 'Corinthians - SP', out['nome']
        assert_equal 2, out['atletas'].size
      end
    end
  end
end
