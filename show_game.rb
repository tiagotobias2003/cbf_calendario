# frozen_string_literal: true

# Relatório de partida CBF: várias planilhas (CSV) + impressão progressiva no terminal.
# Uso: ruby show_game.rb [id_jogo]

require 'csv'
require 'json'
require 'net/http'
require 'openssl'
require 'open-uri'
require 'uri'

BASE = 'https://www.cbf.com.br'

def sep(char = '─')
  puts char * 56
end

def titulo(txt)
  sep
  puts txt
  sep
end

def passo(atual, total, msg)
  print "[#{atual}/#{total}] #{msg}"
  $stdout.flush
end

def passo_ok(extra = nil)
  puts extra ? " ✓ #{extra}" : ' ✓'
end

def passo_erro(e)
  puts " ✗ #{e.class}: #{e.message}"
end

def cbf_ssl_cert_store
  @cbf_ssl_cert_store ||= OpenSSL::X509::Store.new.tap do |store|
    root_pkcs7 = URI('http://crt.sectigo.com/SectigoPublicServerAuthenticationRootR46.p7c').open.read
    OpenSSL::PKCS7.new(root_pkcs7).certificates.uniq { |c| c.to_der }.each { |c| store.add_cert(c) }

    intermediate_der = URI('http://crt.sectigo.com/SectigoPublicServerAuthenticationCAOVR36.crt').open.read
    store.add_cert(OpenSSL::X509::Certificate.new(intermediate_der))
  end
end

def cbf_request(uri, method: :get)
  Net::HTTP.start(
    uri.host,
    uri.port,
    read_timeout: 45,
    open_timeout: 15,
    use_ssl: true,
    verify_mode: OpenSSL::SSL::VERIFY_PEER,
    cert_store: cbf_ssl_cert_store
  ) do |http|
    case method
    when :head then http.head(uri.request_uri)
    when :get then http.get(uri.request_uri)
    else raise ArgumentError, method.to_s
    end
  end
end

def cbf_head_abs(url)
  uri = URI(url)
  return nil unless uri.host == 'www.cbf.com.br'

  cbf_request(uri, method: :head).code
rescue StandardError => e
  "erro: #{e.message}"
end

def head_url_generico(url)
  uri = URI(url)
  return nil if uri.scheme !~ /\Ahttps?\z/

  Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', read_timeout: 12, open_timeout: 8) do |http|
    http.head(uri.request_uri)
  end.code
rescue StandardError => e
  "erro: #{e.message}"
end

def cbf_get_json(path)
  uri = URI.join(BASE, path)
  req = Net::HTTP::Get.new(uri)
  req['Accept'] = 'application/json'
  res = cbf_request(uri, method: :get)
  [res, uri]
end

def cbf_get_html(path)
  uri = URI.join(BASE, path)
  res = cbf_request(uri, method: :get)
  return nil unless res.is_a?(Net::HTTPSuccess)

  res.body&.force_encoding(Encoding::UTF_8)
rescue StandardError
  nil
end

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

def path_pagina_jogo(jogo)
  camp = jogo.dig('campeonato', 'nome')
  serie = jogo.dig('campeonato', 'nome_categoria')
  ano = (jogo.dig('campeonato', 'ano') || jogo['ano']).to_s
  sm = slug_segment(jogo.dig('mandante', 'nome'))
  sv = slug_segment(jogo.dig('visitante', 'nome'))
  id = jogo['id_jogo']

  "/futebol-brasileiro/jogos/#{segmento_campeonato(camp)}/#{segmento_categoria(serie)}/#{ano}/#{sm}-x-#{sv}/#{id}"
end

def url_time(campeonato_nome, categoria_nome, ano, clube_id)
  "#{BASE}/futebol-brasileiro/times/#{segmento_campeonato(campeonato_nome)}/#{segmento_categoria(categoria_nome)}/#{ano}/#{clube_id}"
end

def coletar_links_html(html)
  return [] if html.nil? || html.empty?

  html.scan(%r{href="(/futebol-brasileiro[^"#]*)"}i).flatten.uniq.sort
end

def estatisticas_agregadas(jogo)
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

def ler_id_jogo
  loop do
    print 'ID do jogo na CBF (apenas números): '
    $stdout.flush
    linha = gets
    abort "\nEntrada encerrada." if linha.nil?

    id = linha.strip
    return id if id.match?(/\A\d+\z/)

    puts 'Use só dígitos, ex.: 832024.'
  end
end

def csv_write(path, headers, rows)
  CSV.open(path, 'wb') do |csv|
    csv << headers
    rows.each { |row| csv << row }
  end
  path
end

TOTAIS_PASSOS = 10

# --- início ---

puts <<~BANNER

  Relatório de jogo — CBF (planilhas + terminal)
BANNER

id = ARGV[0]&.strip
id = ler_id_jogo if id.nil? || id.empty?

prefixo = "show_game_#{id}"
gerados = []

passo(1, TOTAIS_PASSOS, 'Baixando dados da API (/api/cbf/jogos/…)…')
begin
  res, uri_api = cbf_get_json("/api/cbf/jogos/#{id}")
  unless res.is_a?(Net::HTTPSuccess)
    passo_erro(StandardError.new("HTTP #{res.code}"))
    warn res.body.to_s[0, 400]
    exit 1
  end
  payload = JSON.parse(res.body)
  jogo = payload['jogo']
  raise 'Resposta sem objeto "jogo"' unless jogo.is_a?(Hash)

  passo_ok("#{uri_api}")
rescue StandardError => e
  passo_erro(e)
  exit 1
end

cp = jogo['campeonato'] || {}
ano_temp = (cp['ano'] || jogo['ano']).to_s
regs = jogo['registros']
regs = [] unless regs.is_a?(Array)
gols_regs = regs.select { |r| r['tipo'] == 'GOL' }

# Planilha + JSON completo
passo(2, TOTAIS_PASSOS, 'Gravando dados brutos (JSON)…')
json_path = "#{prefixo}_dados_completos.json"
File.write(json_path, JSON.pretty_generate(payload))
gerados << json_path
passo_ok(json_path)

passo(3, TOTAIS_PASSOS, 'Planilha: resumo da partida…')
m = jogo.dig('mandante', 'nome')
v = jogo.dig('visitante', 'nome')
gm = jogo.dig('mandante', 'gols')
gv = jogo.dig('visitante', 'gols')
placar_txt = (gm.nil? && gv.nil?) ? '' : "#{gm} x #{gv}"

linhas_resumo = [
  ['ID jogo', jogo['id_jogo']],
  ['Nº jogo', jogo['num_jogo']],
  ['Competição', cp['nome']],
  ['Categoria', cp['nome_categoria']],
  ['Ano', ano_temp],
  ['Rodada', jogo['rodada']],
  ['Etapa', jogo['etapa']],
  ['Data', jogo['data'].to_s.strip],
  ['Horário', jogo['hora'].to_s.strip],
  ['Local', jogo['local'].to_s.strip],
  ['Mandante', m],
  ['Gols mandante (API)', gm.to_s],
  ['Visitante', v],
  ['Gols visitante (API)', gv.to_s],
  ['Placar (API)', placar_txt],
  ['Canais / transmissão', jogo['canais'].to_s.strip],
  ['Alterações de súmula (qtd)', jogo['qtd_alteracoes_jogo'].to_s]
]
p_resumo = csv_write("#{prefixo}_01_resumo.csv", %w[campo valor], linhas_resumo)
gerados << p_resumo
passo_ok(p_resumo)

stats = estatisticas_agregadas(jogo)

passo(4, TOTAIS_PASSOS, 'Planilha: estatísticas agregadas (eventos)…')
rows_ev = stats[:por_tipo_evento].sort.map { |tipo, q| [tipo.to_s, q] }
p_ev = csv_write("#{prefixo}_02_estatisticas_eventos.csv", %w[tipo_evento quantidade], rows_ev)
gerados << p_ev

rows_gt = stats[:gols_por_classificacao_sumula].sort.map { |tipo, q| [tipo.to_s, q] }
legenda = 'NR=normal FT=falta PN=pênalti CT=contra (uso habitual em súmulas)'
p_gt = csv_write("#{prefixo}_03_gols_por_tipo_sumula.csv", %w[tipo_resultado quantidade], rows_gt)
gerados << p_gt
passo_ok("#{p_ev} + #{p_gt} (#{legenda})")

passo(5, TOTAIS_PASSOS, 'Planilha: placar derivado dos eventos + cartões…')
rows_placar_evt = [
  ['Gols mandante (contagem em registros GOL)', stats[:gols_mandante_em_eventos]],
  ['Gols visitante (contagem em registros GOL)', stats[:gols_visitante_em_eventos]]
]
rows_cart = stats[:cartoes_por_resultado].sort.map { |k, q| [k.to_s, q] }
p_pl = csv_write("#{prefixo}_04_placar_eventos.csv", %w[indicador valor], rows_placar_evt)
p_ca = csv_write("#{prefixo}_05_disciplina_resumo.csv", %w[tipo_cartao_falta quantidade], rows_cart)
gerados << p_pl << p_ca
passo_ok("#{p_pl}, #{p_ca}")

passo(6, TOTAIS_PASSOS, 'Planilhas: gols, disciplina (detalhe), todos os eventos…')
if regs.empty?
  puts ' (sem registros na API)'
else
  pen_regs = regs.select { |r| r['tipo'] == 'PENALIDADE' }
  ch_g = gols_regs.flat_map(&:keys).uniq
  ch_p = pen_regs.flat_map(&:keys).uniq
  ch_all = regs.flat_map(&:keys).uniq

  p_g = csv_write("#{prefixo}_06_gols_detalhe.csv", ch_g, gols_regs.map { |r| ch_g.map { |k| r[k] } })
  p_d = csv_write("#{prefixo}_07_disciplina_detalhe.csv", ch_p, pen_regs.map { |r| ch_p.map { |k| r[k] } })
  p_all = csv_write("#{prefixo}_08_eventos_completos.csv", ch_all, regs.map { |r| ch_all.map { |k| r[k] } })
  gerados << p_g << p_d << p_all
  passo_ok("#{gols_regs.size} gols, #{pen_regs.size} ocorr. disciplina, #{regs.size} eventos")
end

passo(7, TOTAIS_PASSOS, 'Planilhas: escalação e substituições…')
csv_write("#{prefixo}_09_escalacao.csv", %w[lado numero reserva goleiro entrou_jogando nome apelido id_atleta],
          %w[mandante visitante].flat_map do |lado|
            (jogo.dig(lado, 'atletas') || []).map do |a|
              [lado, a['numero_camisa'], a['reserva'], a['goleiro'], a['entrou_jogando'], a['nome'], a['apelido'], a['id']]
            end
          end)
gerados << "#{prefixo}_09_escalacao.csv"

sub_rows = []
%w[mandante visitante].each do |lado|
  (jogo.dig(lado, 'alteracoes') || []).each do |alt|
    sub_rows << [
      lado,
      alt['codigo_jogador_saiu'],
      alt['codigo_jogador_entrou'],
      alt['tempo_jogo'],
      alt['tempo_subs'],
      alt['tempo_acrescimo']
    ]
  end
end
csv_write("#{prefixo}_10_substituicoes.csv",
          %w[lado codigo_saiu codigo_entrou tempo_jogo tempo_subs tempo_acrescimo], sub_rows)
gerados << "#{prefixo}_10_substituicoes.csv"
passo_ok("#{stats[:total_substituicoes_mandante] + stats[:total_substituicoes_visitante]} subs")

passo(8, TOTAIS_PASSOS, 'Planilha: arbitragem…')
arb = Array(jogo['arbitros'])
csv_write("#{prefixo}_11_arbitragem.csv", %w[funcao nome uf categoria id],
          arb.map { |a| [a['funcao'], a['nome'], a['uf'], a['categoria'], a['id']] })
gerados << "#{prefixo}_11_arbitragem.csv"
passo_ok("#{arb.size} árbitros/comissão")

passo(9, TOTAIS_PASSOS, 'Planilhas: documentos, links e verificação HTTP…')
docs = jogo['documentos'] || []
csv_write("#{prefixo}_12_documentos.csv", %w[titulo url],
          docs.map { |d| [d['title'], d['url']] })
gerados << "#{prefixo}_12_documentos.csv"

pagina = "#{BASE}#{path_pagina_jogo(jogo)}"
tm = url_time(cp['nome'], cp['nome_categoria'], ano_temp, jogo.dig('mandante', 'id'))
tv = url_time(cp['nome'], cp['nome_categoria'], ano_temp, jogo.dig('visitante', 'id'))

html = cbf_get_html(path_pagina_jogo(jogo))
links_internos = coletar_links_html(html)

rows_links = [
  ['API JSON', uri_api.to_s, '—'],
  ['Página da partida', pagina, cbf_head_abs(pagina).to_s],
  ['Time mandante', tm, cbf_head_abs(tm).to_s],
  ['Time visitante', tv, cbf_head_abs(tv).to_s]
]
docs.each_with_index do |d, i|
  rows_links << ["Documento: #{d['title']}", d['url'], head_url_generico(d['url']).to_s]
end
links_internos.first(25).each_with_index do |path, i|
  rows_links << ["Link interno #{i + 1}", "#{BASE}#{path}", cbf_head_abs("#{BASE}#{path}").to_s]
end

csv_write("#{prefixo}_13_links.csv", %w[descricao url http_status], rows_links)
gerados << "#{prefixo}_13_links.csv"
passo_ok("#{links_internos.size} links internos na página (até 25 verificados no CSV)")

# --- Relatório textual no terminal (estilo next_games) ---
passo(10, TOTAIS_PASSOS, 'Emitindo relatório no terminal…')
passo_ok

titulo "PARTIDA: #{m} x #{v}"
puts "ID #{id}  |  Placar (API): #{placar_txt.empty? ? '(sem gols na API / não finalizado)' : placar_txt}"
puts "#{cp['nome']} — #{cp['nome_categoria']} — #{ano_temp}  |  Rodada #{jogo['rodada']}  |  #{jogo['data'].to_s.strip} às #{jogo['hora'].to_s.strip}"
puts "Local: #{jogo['local']}"
puts "Transmissão: #{jogo['canais']}" if jogo['canais'].to_s.strip != ''

titulo 'Estatísticas (derivadas dos registros da súmula)'
puts "Total de eventos: #{regs.size}"
stats[:por_tipo_evento].sort.each { |t, q| puts "  • #{t}: #{q}" }
puts "\nGols por tipo (campo resultado):"
stats[:gols_por_classificacao_sumula].sort.each { |t, q| puts "  • #{t}: #{q}" }
puts "\nPlacar por contagem de gols nos registros: #{stats[:gols_mandante_em_eventos]} x #{stats[:gols_visitante_em_eventos]}"
puts 'Cartões / faltas (campo resultado em PENALIDADE):'
stats[:cartoes_por_resultado].sort.each { |t, q| puts "  • #{t}: #{q}" }
puts "\nSubstituições: mandante #{stats[:total_substituicoes_mandante]}, visitante #{stats[:total_substituicoes_visitante]}"

if gols_regs.any?
  titulo 'Gols (ordem da súmula)'
  gols_regs.each do |r|
    puts "  #{r['minutos']}  #{r['clube']}  #{r['atleta_apelido']}  [#{r['resultado']}]"
  end
end

titulo 'Árbitros'
arb.each { |a| puts "  #{a['funcao']}: #{a['nome']} (#{a['uf']}) — #{a['categoria']}" }

titulo 'Documentos oficiais'
docs.each { |d| puts "  • #{d['title']}: #{d['url']}" }

titulo 'Links principais'
puts "  Partida: #{pagina}"
puts "  Mandante: #{tm}"
puts "  Visitante: #{tv}"

titulo 'Arquivos gerados (planilhas e dados)'
gerados.uniq.sort.each { |f| puts "  • #{f}" }

sep('=')
puts 'Obs.: posse, chutes e finalizações não vêm nesta API; use eventos e documentos PDF quando precisar.'
puts "Relatório concluído — #{gerados.uniq.size} arquivo(s)."
sep('=')
