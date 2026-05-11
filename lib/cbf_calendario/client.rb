# frozen_string_literal: true

require 'date'
require 'json'
require 'net/http'
require 'openssl'
require 'open-uri'
require 'set'
require 'uri'

module CbfCalendario
  class Error < StandardError; end
  class HttpError < Error; end
  class InvalidDateError < Error; end
  class InvalidGameIdError < Error; end

  class Client
    DEFAULT_BASE = 'https://www.cbf.com.br'

    attr_reader :base_url, :read_timeout, :open_timeout

    def initialize(base_url: DEFAULT_BASE, read_timeout: 30, open_timeout: 15)
      @base_url = base_url.to_s.chomp('/')
      @read_timeout = read_timeout
      @open_timeout = open_timeout
    end

    # GET /api/cbf/jogos/:id — resposta completa da API (mesmo conteúdo que +show_game.rb+ grava em JSON).
    # Chaves são +String+ como no JSON original.
    def partida_completa(id_jogo)
      jid = Client.normalize_id_jogo!(id_jogo)
      payload = get_json(api_path_jogo(jid))
      raise HttpError, 'Resposta sem objeto "jogo"' unless payload['jogo'].is_a?(Hash)

      payload
    end

    # Apenas +payload['jogo']+ (Hash com string keys).
    def jogo_partida(id_jogo)
      partida_completa(id_jogo)['jogo']
    end

    def self.normalize_id_jogo!(id_jogo)
      s = id_jogo.to_s.strip
      raise InvalidGameIdError, 'id_jogo deve conter só dígitos (ex.: 832024)' unless s.match?(/\A\d+\z/)

      s
    end

    # Aceita Date, Time ou String "dd/mm/aaaa".
    # Retorna todos os jogos do dia no calendário (pendentes e já realizados).
    # Array<Hash> com símbolos como chaves, ordenado e sem IDs duplicados.
    # Cada hash: +campeonato+, +serie+, +mandante+, +visitante+, +horario+, +placar+,
    # +data+, +data_iso+, +local+, +rodada+, +id_jogo+.
    def jogos_do_dia(data)
      date = Client.coerce_date!(data)
      payload = get_json(api_path_calendario(date))
      jogos = extrair_jogos_do_dia(payload, date)
      dedup_and_sort(jogos)
    end

    # Payload bruto da API para o dia (Hash).
    def calendario_json(data)
      date = Client.coerce_date!(data)
      get_json(api_path_calendario(date))
    end

    def self.coerce_date!(data)
      case data
      when Date then data
      when Time then data.to_date
      else
        parse_data_br!(data)
      end
    end

    def self.parse_data_br!(str)
      m = str.to_s.strip.match(/\A(\d{2})\/(\d{2})\/(\d{4})\z/)
      raise InvalidDateError, 'Use dd/mm/aaaa (ex.: 15/05/2026)' unless m

      day = m[1].to_i
      month = m[2].to_i
      year = m[3].to_i
      Date.new(year, month, day)
    rescue ArgumentError
      raise InvalidDateError, 'Data inválida'
    end

    private

    def api_path_calendario(data)
      format('/api/cbf/calendario/jogos/%04d/%02d/%02d', data.year, data.month, data.day)
    end

    def api_path_jogo(id_jogo)
      "/api/cbf/jogos/#{id_jogo}"
    end

    def get_json(path)
      uri = URI.join(base_url, path)
      request_json(uri)
    end

    def request_json(uri)
      res = perform_get(uri, accept: 'application/json')
      JSON.parse(res.body)
    end

    def perform_get(uri, accept:, redirects_left: 5)
      Net::HTTP.start(
        uri.host,
        uri.port,
        read_timeout: read_timeout,
        open_timeout: open_timeout,
        use_ssl: true,
        verify_mode: OpenSSL::SSL::VERIFY_PEER,
        cert_store: ssl_cert_store
      ) do |http|
        req = Net::HTTP::Get.new(uri)
        req['Accept'] = accept
        res = http.request(req)

        if res.is_a?(Net::HTTPRedirection)
          raise HttpError, 'Muitas redireções na requisição HTTP' if redirects_left <= 0

          location = res['location'].to_s
          raise HttpError, 'Redirecionamento HTTP sem header Location' if location.empty?

          next_uri = URI.join(uri.to_s, location)
          return perform_get(next_uri, accept: accept, redirects_left: redirects_left - 1)
        end

        unless res.is_a?(Net::HTTPSuccess)
          raise HttpError, "HTTP #{res.code}: #{res.message}"
        end

        res
      end
    end

    def ssl_cert_store
      @ssl_cert_store ||= OpenSSL::X509::Store.new.tap do |store|
        root_pkcs7 = URI('http://crt.sectigo.com/SectigoPublicServerAuthenticationRootR46.p7c').open.read
        OpenSSL::PKCS7.new(root_pkcs7).certificates.uniq { |c| c.to_der }.each { |c| store.add_cert(c) }

        intermediate_der = URI('http://crt.sectigo.com/SectigoPublicServerAuthenticationCAOVR36.crt').open.read
        store.add_cert(OpenSSL::X509::Certificate.new(intermediate_der))
      end
    end

    def horario_jogo(jogo)
      jogo['hora'].to_s.strip
    end

    def placar_partida(jogo)
      gm = jogo.dig('mandante', 'gols')
      gv = jogo.dig('visitante', 'gols')
      return nil if gm.nil? || gv.nil?

      "#{gm} x #{gv}"
    end

    def extrair_jogos_do_dia(payload, data_calendario)
      raiz = payload['jogos'] || {}
      linhas = []

      raiz.each do |campeonato, por_serie|
        next unless por_serie.is_a?(Hash)

        por_serie.each do |serie, lista|
          next unless lista.is_a?(Array)

          lista.each do |jogo|
            linhas << {
              campeonato: campeonato.to_s.strip,
              serie: serie.to_s.strip,
              mandante: jogo.dig('mandante', 'nome').to_s.strip,
              visitante: jogo.dig('visitante', 'nome').to_s.strip,
              horario: horario_jogo(jogo),
              placar: placar_partida(jogo),
              data: jogo['data'].to_s.strip,
              data_iso: data_calendario.strftime('%Y-%m-%d'),
              local: jogo['local'].to_s.strip,
              rodada: jogo['rodada'].to_s.strip,
              id_jogo: jogo['id_jogo'].to_s.strip
            }
          end
        end
      end

      linhas
    end

    def dedup_and_sort(linhas)
      seen = Set.new
      out = []
      linhas.each do |row|
        id = row[:id_jogo]
        next if id.empty? || seen.include?(id)

        seen.add(id)
        out << row
      end
      out.sort_by { |j| [j[:campeonato], j[:serie], j[:rodada].to_i, j[:id_jogo]] }
    end

  end
end
