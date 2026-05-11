# cbf_calendario

Gem Ruby para consultar a API pública da CBF e retornar dados prontos para uso.

## O que a gem faz

- Lista todos os jogos do dia (calendário da API).
- Busca a partida completa por `id_jogo`.
- Gera estatísticas agregadas da súmula.
- Monta URLs públicas da CBF (partida e times).
- Retorna hashes Ruby para facilitar integração.

## Instalação

```ruby
# Gemfile
gem 'cbf_calendario', '~> 0.2'
```

```bash
bundle install
```

Ou em script Ruby:

```bash
gem install cbf_calendario
```

```ruby
require 'cbf_calendario'
```

## Uso rápido

```ruby
require 'cbf_calendario'

jogos = CbfCalendario.jogos_do_dia('10/05/2026')
partida = CbfCalendario.partida_completa('832031')
jogo = CbfCalendario.jogo_partida('832031')
stats = CbfCalendario.estatisticas_agregadas(jogo)
```

## Funcionalidades principais

### 1) Jogos do dia

Retorna todas as partidas previstas ou já disputadas naquela data, conforme o calendário da CBF. Quando a API já trouxer placar, o campo `placar` vem preenchido (ex.: `"2 x 1"`); caso contrário, `placar` fica `nil` e `horario` reflete o horário previsto, se existir.

### 2) Partida completa por ID

Consulta `GET /api/cbf/jogos/:id` e devolve o payload completo da API.

### 3) Estatísticas da súmula

Agrega eventos como gols, penalidades/cartões e substituições.

### 4) URLs públicas da CBF

Monta links da página da partida e das páginas de times.

## Referência completa de funções públicas

### Módulo `CbfCalendario` (atalhos)

- `CbfCalendario.parse_data_br!(str)`
- `CbfCalendario.jogos_do_dia(data, **opts)`
- `CbfCalendario.partida_completa(id_jogo, **opts)`
- `CbfCalendario.jogo_partida(id_jogo, **opts)`
- `CbfCalendario.estatisticas_agregadas(jogo)`

### Classe `CbfCalendario::Client`

- `CbfCalendario::Client.new(base_url: ..., read_timeout: ..., open_timeout: ...)`
- `client.jogos_do_dia(data)`
- `client.calendario_json(data)`
- `client.partida_completa(id_jogo)`
- `client.jogo_partida(id_jogo)`
- `CbfCalendario::Client.parse_data_br!(str)`
- `CbfCalendario::Client.coerce_date!(data)`
- `CbfCalendario::Client.normalize_id_jogo!(id_jogo)`

### Módulo `CbfCalendario::PartidaStats`

- `CbfCalendario::PartidaStats.agregadas(jogo)`

### Módulo `CbfCalendario::Urls`

- `CbfCalendario::Urls.slug_segment(str)`
- `CbfCalendario::Urls.segmento_campeonato(nome)`
- `CbfCalendario::Urls.segmento_categoria(nome_serie)`
- `CbfCalendario::Urls.path_pagina_jogo(jogo)`
- `CbfCalendario::Urls.url_time(campeonato_nome, categoria_nome, ano, clube_id, base: ...)`
- `CbfCalendario::Urls.url_pagina_partida(jogo, base: ...)`

### Constante

- `CbfCalendario::VERSION`

## Exemplos de respostas (retornos)

### `CbfCalendario.parse_data_br!('25/12/2026')`

```ruby
# => #<Date: 2026-12-25 ...>
```

### `CbfCalendario.jogos_do_dia('10/05/2026')`

```ruby
# => [
#      {
#        campeonato: "Campeonato Brasileiro",
#        serie: "Série A",
#        mandante: "Flamengo",
#        visitante: "Bahia",
#        horario: "16:00",
#        placar: nil,
#        data: "10/05/2026",
#        data_iso: "2026-05-10",
#        local: "Maracanã",
#        rodada: "6",
#        id_jogo: "832031"
#      },
#      {
#        campeonato: "Campeonato Brasileiro",
#        serie: "Série A",
#        mandante: "Palmeiras",
#        visitante: "São Paulo",
#        horario: "",
#        placar: "1 x 0",
#        data: "10/05/2026",
#        data_iso: "2026-05-10",
#        local: "Allianz Parque",
#        rodada: "6",
#        id_jogo: "832032"
#      }
#    ]
```

### `client.calendario_json(Date.today)`

```ruby
# => {
#      "jogos" => {
#        "Campeonato Brasileiro" => {
#          "Série A" => [
#            { "id_jogo" => 832031, "mandante" => {...}, "visitante" => {...}, ... }
#          ]
#        }
#      }
#    }
```

### `CbfCalendario.partida_completa('832031')`

```ruby
# => {
#      "jogo" => {
#        "id_jogo" => 832031,
#        "mandante" => { "id" => 1, "nome" => "Flamengo", "gols" => 2, ... },
#        "visitante" => { "id" => 2, "nome" => "Bahia", "gols" => 1, ... },
#        "registros" => [ ... ],
#        ...
#      }
#    }
```

### `CbfCalendario.jogo_partida('832031')`

```ruby
# => {
#      "id_jogo" => 832031,
#      "campeonato" => { "nome" => "Campeonato Brasileiro", "nome_categoria" => "Série A", "ano" => 2026 },
#      "mandante" => { "id" => 1, "nome" => "Flamengo", ... },
#      "visitante" => { "id" => 2, "nome" => "Bahia", ... },
#      "registros" => [ ... ]
#    }
```

### `CbfCalendario.estatisticas_agregadas(jogo)`

```ruby
# => {
#      por_tipo_evento: { "GOL" => 3, "PENALIDADE" => 5 },
#      gols_por_classificacao_sumula: { "NORMAL" => 2, "CONTRA" => 1 },
#      gols_mandante_em_eventos: 2,
#      gols_visitante_em_eventos: 1,
#      cartoes_por_resultado: { "AMARELO" => 4, "VERMELHO" => 1 },
#      total_substituicoes_mandante: 5,
#      total_substituicoes_visitante: 4
#    }
```

### `CbfCalendario::Urls.url_pagina_partida(jogo)`

```ruby
# => "https://www.cbf.com.br/futebol-brasileiro/jogos/campeonato-brasileiro/serie-a/2026/flamengo-x-bahia/832031"
```

### `CbfCalendario::Urls.url_time(...)`

```ruby
# => "https://www.cbf.com.br/futebol-brasileiro/times/campeonato-brasileiro/serie-a/2026/1"
```

## Tratamento de erros

- `CbfCalendario::InvalidDateError`: data inválida (formato esperado: `dd/mm/aaaa`).
- `CbfCalendario::InvalidGameIdError`: `id_jogo` inválido (somente dígitos).
- `CbfCalendario::HttpError`: erro HTTP ou payload inválido da API.
- `CbfCalendario::Error`: classe base.

## Uso em Rails (recomendado)

Para produção, use em background com Active Job (ex.: Solid Queue), evitando bloquear requests web:

```ruby
class CbfCalendarioSyncJob < ApplicationJob
  queue_as :default

  def perform(data_iso: nil)
    data = data_iso ? Date.iso8601(data_iso) : Date.current
    CbfCalendario.jogos_do_dia(data)
  end
end
```

## Requisitos

- Ruby >= 3.0

## Licença

MIT. Veja `LICENSE.txt`.