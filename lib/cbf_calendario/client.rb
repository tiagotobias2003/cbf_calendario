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
  class InvalidClubIdError < Error; end
  class InvalidAthleteIdError < Error; end

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

    # GET /api/cbf/atletas/:id_clube — retorna hash com dados dos atletas.
    # Saída: { clube_id: "123", atletas: [ ... ] }
    def atletas_do_clube(id_clube)
      cid = Client.normalize_id_clube!(id_clube)
      payload = get_json(api_path_atletas_clube(cid))
      atletas =
        if payload.is_a?(Array)
          payload
        elsif payload.is_a?(Hash) && payload['atletas'].is_a?(Array)
          payload['atletas']
        else
          raise HttpError, 'Resposta sem lista de atletas'
        end

      { clube_id: cid, atletas: atletas }
    end

    # Busca dados completos de um clube por ID.
    # Saída: { clube_id: "123", clube: { ... } }
    def clube_por_id(id_clube)
      cid = Client.normalize_id_clube!(id_clube)
      payload = buscar_clube_payload(cid)
      clube = extrair_clube_do_payload(payload, cid)
      raise HttpError, 'Resposta sem dados do clube' unless clube.is_a?(Hash) && !clube.empty?

      { clube_id: cid, clube: clube }
    end

    # Busca dados completos de um atleta por ID.
    # Saída: { atleta_id: "123", atleta: { ... } }
    def atleta_por_id(id_atleta)
      aid = Client.normalize_id_atleta!(id_atleta)
      payload = buscar_atleta_payload(aid)
      atleta = extrair_atleta_do_payload(payload, aid)
      raise HttpError, 'Resposta sem dados do atleta' unless atleta.is_a?(Hash) && !atleta.empty?

      { atleta_id: aid, atleta: atleta }
    end

    def self.normalize_id_jogo!(id_jogo)
      s = id_jogo.to_s.strip
      raise InvalidGameIdError, 'id_jogo deve conter só dígitos (ex.: 832024)' unless s.match?(/\A\d+\z/)

      s
    end

    def self.normalize_id_clube!(id_clube)
      s = id_clube.to_s.strip
      raise InvalidClubIdError, 'id_clube deve conter só dígitos (ex.: 20001)' unless s.match?(/\A\d+\z/)

      s
    end

    def self.normalize_id_atleta!(id_atleta)
      s = id_atleta.to_s.strip
      raise InvalidAthleteIdError, 'id_atleta deve conter só dígitos (ex.: 12345)' unless s.match?(/\A\d+\z/)

      s
    end

    # Aceita Date, Time ou String "dd/mm/aaaa".
    # Retorna Array<Hash> com símbolos como chaves, ordenado e sem IDs duplicados.
    # Cada hash: +campeonato+, +serie+, +mandante+, +visitante+, +horario+,
    # +data+, +data_iso+, +local+, +rodada+, +id_jogo+.
    def jogos_pendentes_no_dia(data)
      date = Client.coerce_date!(data)
      payload = get_json(api_path_calendario(date))
      jogos = extrair_jogos_pendentes(payload, date)
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

    def api_path_atletas_clube(id_clube)
      "/api/cbf/atletas/#{id_clube}"
    end

    def api_path_atleta(id_atleta)
      "/api/cbf/atleta/#{id_atleta}"
    end

    def api_path_atletas_detalhes(id_atleta)
      "/api/cbf/atletas/detalhes/#{id_atleta}"
    end

    def api_path_clube(id_clube)
      "/api/cbf/clubes/#{id_clube}"
    end

    def api_path_time(id_clube)
      "/api/cbf/times/#{id_clube}"
    end

    def api_path_clube_detalhes(id_clube)
      "/api/cbf/clubes/detalhes/#{id_clube}"
    end

    def get_json(path)
      uri = URI.join(base_url, path)
      request_json(uri)
    end

    def request_json(uri)
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
        req['Accept'] = 'application/json'
        res = http.request(req)
        unless res.is_a?(Net::HTTPSuccess)
          raise HttpError, "HTTP #{res.code}: #{res.message}"
        end

        JSON.parse(res.body)
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

    def jogo_sem_placar?(jogo)
      gm = jogo.dig('mandante', 'gols')
      gv = jogo.dig('visitante', 'gols')
      gm.nil? || gv.nil?
    end

    def extrair_jogos_pendentes(payload, data_calendario)
      raiz = payload['jogos'] || {}
      linhas = []

      raiz.each do |campeonato, por_serie|
        next unless por_serie.is_a?(Hash)

        por_serie.each do |serie, lista|
          next unless lista.is_a?(Array)

          lista.each do |jogo|
            next unless jogo_sem_placar?(jogo)

            linhas << {
              campeonato: campeonato.to_s.strip,
              serie: serie.to_s.strip,
              mandante: jogo.dig('mandante', 'nome').to_s.strip,
              visitante: jogo.dig('visitante', 'nome').to_s.strip,
              horario: horario_jogo(jogo),
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

    def buscar_atleta_payload(id_atleta)
      paths = [
        api_path_atleta(id_atleta),
        api_path_atletas_detalhes(id_atleta),
        api_path_atletas_clube(id_atleta)
      ]

      errors = []
      paths.each do |path|
        begin
          return get_json(path)
        rescue HttpError => e
          errors << "#{path}: #{e.message}"
        end
      end

      raise HttpError, "Não foi possível buscar o atleta #{id_atleta}. Tentativas: #{errors.join(' | ')}"
    end

    def extrair_atleta_do_payload(payload, id_atleta)
      if payload.is_a?(Hash)
        return payload if campo_id_atleta(payload) == id_atleta
        return payload['atleta'] if payload['atleta'].is_a?(Hash)
        return payload
      end

      return {} unless payload.is_a?(Array)

      payload.find { |item| item.is_a?(Hash) && campo_id_atleta(item) == id_atleta } ||
        payload.find { |item| item.is_a?(Hash) } || {}
    end

    def campo_id_atleta(hash)
      hash['id_atleta'].to_s.strip.empty? ? hash['id'].to_s.strip : hash['id_atleta'].to_s.strip
    end

    def buscar_clube_payload(id_clube)
      paths = [
        api_path_clube(id_clube),
        api_path_time(id_clube),
        api_path_clube_detalhes(id_clube)
      ]

      errors = []
      paths.each do |path|
        begin
          return get_json(path)
        rescue HttpError => e
          errors << "#{path}: #{e.message}"
        end
      end

      raise HttpError, "Não foi possível buscar o clube #{id_clube}. Tentativas: #{errors.join(' | ')}"
    end

    def extrair_clube_do_payload(payload, id_clube)
      if payload.is_a?(Hash)
        return payload if campo_id_clube(payload) == id_clube
        return payload['clube'] if payload['clube'].is_a?(Hash)
        return payload['time'] if payload['time'].is_a?(Hash)
        return payload
      end

      return {} unless payload.is_a?(Array)

      payload.find { |item| item.is_a?(Hash) && campo_id_clube(item) == id_clube } ||
        payload.find { |item| item.is_a?(Hash) } || {}
    end

    def campo_id_clube(hash)
      return hash['id_clube'].to_s.strip unless hash['id_clube'].to_s.strip.empty?
      return hash['id_time'].to_s.strip unless hash['id_time'].to_s.strip.empty?

      hash['id'].to_s.strip
    end
  end
end
