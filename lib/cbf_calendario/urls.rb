# frozen_string_literal: true

module CbfCalendario
  # Montagem de paths e URLs públicas da CBF (mesma lógica de +show_game.rb+).
  module Urls
    SITE_ROOT = 'https://www.cbf.com.br'

    module_function

    def slug_segment(str)
      t = str.to_s.unicode_normalize(:nfd).gsub(/\p{M}/u, '').downcase
      t.gsub(/[^a-z0-9]+/, '-').gsub(/-+/, '-').delete_prefix('-').delete_suffix('-')
    end

    def segmento_campeonato(nome)
      n = nome.to_s.strip
      return 'campeonato-brasileiro' if n.match?(/\ACampeonato Brasileiro\z/i)
      return 'copa-do-brasil' if n.match?(/\ACopa do Brasil\z/i)
      return 'brasileiro-feminino' if n.match?(/\ABrasileiro Feminino\z/i)

      slug_segment(n)
    end

    def segmento_categoria(nome_serie)
      s = nome_serie.to_s.strip

      serie = s.match(/\ASérie\s+([ABCD])\z/i)
      return "serie-#{serie[1].downcase}" if serie

      sub = s.match(/\ASub\s*-\s*(\d+)\z/i)
      return "sub-#{sub[1]}" if sub

      ax = s.match(/\A(A[12])\z/i)
      return ax[1].downcase if ax

      slug_segment(s)
    end

    # Path relativo à raiz do site (ex.: +/futebol-brasileiro/jogos/...+).
    def path_pagina_jogo(jogo)
      camp = jogo.dig('campeonato', 'nome')
      serie = jogo.dig('campeonato', 'nome_categoria')
      ano = (jogo.dig('campeonato', 'ano') || jogo['ano']).to_s
      sm = slug_segment(jogo.dig('mandante', 'nome'))
      sv = slug_segment(jogo.dig('visitante', 'nome'))
      id = jogo['id_jogo']

      "/futebol-brasileiro/jogos/#{segmento_campeonato(camp)}/#{segmento_categoria(serie)}/#{ano}/#{sm}-x-#{sv}/#{id}"
    end

    def url_time(campeonato_nome, categoria_nome, ano, clube_id, base: SITE_ROOT)
      base = base.to_s.chomp('/')
      "#{base}/futebol-brasileiro/times/#{segmento_campeonato(campeonato_nome)}/#{segmento_categoria(categoria_nome)}/#{ano}/#{clube_id}"
    end

    def url_pagina_partida(jogo, base: SITE_ROOT)
      "#{base.to_s.chomp('/')}#{path_pagina_jogo(jogo)}"
    end
  end
end
