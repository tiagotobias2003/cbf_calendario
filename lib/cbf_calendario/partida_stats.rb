# frozen_string_literal: true

module CbfCalendario
  # Estatísticas derivadas dos registros da súmula (mesma lógica de +show_game.rb+).
  module PartidaStats
    module_function

    # @param jogo [Hash] objeto +jogo+ retornado pela API (+payload['jogo']+)
    # @return [Hash] chaves em símbolo
    def agregadas(jogo)
      regs = jogo['registros']
      regs = [] unless regs.is_a?(Array)

      por_tipo = regs.each_with_object(Hash.new(0)) { |r, h| h[r['tipo']] += 1 }

      mid = jogo.dig('mandante', 'id').to_s
      vid = jogo.dig('visitante', 'id').to_s

      gols = regs.select { |r| r['tipo'] == 'GOL' }
      gols_tipo = gols.each_with_object(Hash.new(0)) { |r, h| h[r['resultado'].to_s] += 1 }

      gols_m = gols.count { |r| r['clube_id'].to_s == mid }
      gols_v = gols.count { |r| r['clube_id'].to_s == vid }

      pens = regs.select { |r| r['tipo'] == 'PENALIDADE' }
      cartoes = pens.each_with_object(Hash.new(0)) { |r, h| h[r['resultado'].to_s] += 1 }

      {
        por_tipo_evento: por_tipo,
        gols_por_classificacao_sumula: gols_tipo,
        gols_mandante_em_eventos: gols_m,
        gols_visitante_em_eventos: gols_v,
        cartoes_por_resultado: cartoes,
        total_substituicoes_mandante: (jogo.dig('mandante', 'alteracoes') || []).size,
        total_substituicoes_visitante: (jogo.dig('visitante', 'alteracoes') || []).size
      }
    end
  end
end
