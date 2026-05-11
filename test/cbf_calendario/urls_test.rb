# frozen_string_literal: true

require_relative '../test_helper'

module CbfCalendario
  class UrlsTest < Minitest::Test
    def test_slug_segment_removes_accents_and_normalizes
      assert_equal 'campeonato-brasileiro-serie-a', Urls.slug_segment('Campeonato Brasileiro: Série A')
    end

    def test_segmento_campeonato_has_special_cases
      assert_equal 'campeonato-brasileiro', Urls.segmento_campeonato('Campeonato Brasileiro')
      assert_equal 'copa-do-brasil', Urls.segmento_campeonato('Copa do Brasil')
      assert_equal 'brasileiro-feminino', Urls.segmento_campeonato('Brasileiro Feminino')
      assert_equal 'torneio-x', Urls.segmento_campeonato('Torneio X')
    end

    def test_segmento_categoria_handles_common_patterns
      assert_equal 'serie-a', Urls.segmento_categoria('Série A')
      assert_equal 'sub-20', Urls.segmento_categoria('Sub-20')
      assert_equal 'a2', Urls.segmento_categoria('A2')
      assert_equal 'modulo-especial', Urls.segmento_categoria('Módulo Especial')
    end

    def test_path_and_urls_for_match_and_team
      jogo = {
        'id_jogo' => 832031,
        'ano' => 2026,
        'campeonato' => { 'nome' => 'Campeonato Brasileiro', 'nome_categoria' => 'Série A', 'ano' => 2026 },
        'mandante' => { 'nome' => 'Flamengo' },
        'visitante' => { 'nome' => 'Bahia' }
      }

      path = Urls.path_pagina_jogo(jogo)
      assert_equal '/futebol-brasileiro/jogos/campeonato-brasileiro/serie-a/2026/flamengo-x-bahia/832031', path
      assert_equal "https://www.cbf.com.br#{path}", Urls.url_pagina_partida(jogo)

      time_url = Urls.url_time('Campeonato Brasileiro', 'Série A', 2026, 20016)
      assert_equal 'https://www.cbf.com.br/futebol-brasileiro/times/campeonato-brasileiro/serie-a/2026/20016', time_url
    end
  end
end
