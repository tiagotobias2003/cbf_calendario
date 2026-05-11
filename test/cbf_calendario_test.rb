# frozen_string_literal: true

require_relative 'test_helper'

class CbfCalendarioTest < Minitest::Test
  def test_version_constant_exists
    refute_nil CbfCalendario::VERSION
  end

  def test_parse_data_br_bang_delegates_to_client
    expected = Date.new(2026, 5, 11)
    CbfCalendario::Client.stub(:parse_data_br!, expected) do
      assert_equal expected, CbfCalendario.parse_data_br!('11/05/2026')
    end
  end

  def test_jogos_do_dia_delegates_to_client
    fake_client = Minitest::Mock.new
    expected = [{ id_jogo: '123' }]
    fake_client.expect(:jogos_do_dia, expected, ['11/05/2026'])

    CbfCalendario::Client.stub(:new, fake_client) do
      assert_equal expected, CbfCalendario.jogos_do_dia('11/05/2026', read_timeout: 40)
    end

    fake_client.verify
  end

  def test_partida_completa_delegates_to_client
    fake_client = Minitest::Mock.new
    expected = { 'jogo' => { 'id_jogo' => 123 } }
    fake_client.expect(:partida_completa, expected, ['123'])

    CbfCalendario::Client.stub(:new, fake_client) do
      assert_equal expected, CbfCalendario.partida_completa('123')
    end

    fake_client.verify
  end

  def test_jogo_partida_delegates_to_client
    fake_client = Minitest::Mock.new
    expected = { 'id_jogo' => 123 }
    fake_client.expect(:jogo_partida, expected, ['123'])

    CbfCalendario::Client.stub(:new, fake_client) do
      assert_equal expected, CbfCalendario.jogo_partida('123')
    end

    fake_client.verify
  end

  def test_estatisticas_agregadas_delegates_to_partida_stats
    jogo = { 'registros' => [] }
    expected = { por_tipo_evento: {} }

    CbfCalendario::PartidaStats.stub(:agregadas, expected) do
      assert_equal expected, CbfCalendario.estatisticas_agregadas(jogo)
    end
  end
end
