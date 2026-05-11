# cbf_calendario

Gem Ruby para consultar a API pública da CBF e retornar dados prontos para uso.

## O que a gem faz

- Lista jogos pendentes (sem placar) por dia.
- Busca a partida completa por `id_jogo`.
- Busca atletas por `id_clube`.
- Busca atleta por `id_atleta`.
- Busca clube por `id_clube`.
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

jogos = CbfCalendario.jogos_pendentes_no_dia('10/05/2026')
partida = CbfCalendario.partida_completa('832031')
jogo = CbfCalendario.jogo_partida('832031')
atletas = CbfCalendario.atletas_do_clube('20001')
atleta = CbfCalendario.atleta_por_id('12345')
clube = CbfCalendario.clube_por_id('20001')
stats = CbfCalendario.estatisticas_agregadas(jogo)
```

## Funcionalidades principais

### 1) Jogos pendentes por data

Retorna apenas partidas ainda sem placar no dia informado.

### 2) Partida completa por ID

Consulta `GET /api/cbf/jogos/:id` e devolve o payload completo da API.

### 3) Estatísticas da súmula

Agrega eventos como gols, penalidades/cartões e substituições.

### 4) URLs públicas da CBF

Monta links da página da partida e das páginas de times.

## Referência completa de funções públicas

### Módulo `CbfCalendario` (atalhos)

- `CbfCalendario.parse_data_br!(str)`
- `CbfCalendario.jogos_pendentes_no_dia(data, **opts)`
- `CbfCalendario.partida_completa(id_jogo, **opts)`
- `CbfCalendario.jogo_partida(id_jogo, **opts)`
- `CbfCalendario.atletas_do_clube(id_clube, **opts)`
- `CbfCalendario.atleta_por_id(id_atleta, **opts)`
- `CbfCalendario.clube_por_id(id_clube, **opts)`
- `CbfCalendario.estatisticas_agregadas(jogo)`

### Classe `CbfCalendario::Client`

- `CbfCalendario::Client.new(base_url: ..., read_timeout: ..., open_timeout: ...)`
- `client.jogos_pendentes_no_dia(data)`
- `client.calendario_json(data)`
- `client.partida_completa(id_jogo)`
- `client.jogo_partida(id_jogo)`
- `client.atletas_do_clube(id_clube)`
- `client.atleta_por_id(id_atleta)`
- `client.clube_por_id(id_clube)`
- `CbfCalendario::Client.parse_data_br!(str)`
- `CbfCalendario::Client.coerce_date!(data)`
- `CbfCalendario::Client.normalize_id_jogo!(id_jogo)`
- `CbfCalendario::Client.normalize_id_clube!(id_clube)`
- `CbfCalendario::Client.normalize_id_atleta!(id_atleta)`

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

### `CbfCalendario.jogos_pendentes_no_dia('10/05/2026')`

```ruby
# => [
#      {
#        campeonato: "Campeonato Brasileiro",
#        serie: "Série A",
#        mandante: "Flamengo",
#        visitante: "Bahia",
#        placar_ou_horario: "16:00",
#        data: "10/05/2026",
#        data_iso: "2026-05-10",
#        local: "Maracanã",
#        rodada: "6",
#        id_jogo: "832031"
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

### `CbfCalendario.atletas_do_clube('20001')`

```ruby
# => {
#      clube_id: "20001",
#      atletas: [
#        {
#          "id_atleta" => 12345,
#          "nome_popular" => "Atleta Exemplo",
#          "nome_completo" => "Atleta Exemplo da Silva",
#          "posicao" => "MEI",
#          ...
#        }
#      ]
#    }
```

### `CbfCalendario.atleta_por_id('12345')`

```ruby
# => {
#      atleta_id: "12345",
#      atleta: {
#        "id_atleta" => 12345,
#        "nome_popular" => "Atleta Exemplo",
#        "nome_completo" => "Atleta Exemplo da Silva",
#        "posicao" => "ATA",
#        ...
#      }
#    }
```

### `CbfCalendario.clube_por_id('20001')`

```ruby
# => {
#      clube_id: "20001",
#      clube: {
#        "id_clube" => 20001,
#        "nome" => "Time Exemplo",
#        "sigla" => "TEX",
#        "escudo" => "https://...",
#        ...
#      }
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
- `CbfCalendario::InvalidClubIdError`: `id_clube` inválido (somente dígitos).
- `CbfCalendario::InvalidAthleteIdError`: `id_atleta` inválido (somente dígitos).
- `CbfCalendario::HttpError`: erro HTTP ou payload inválido da API.
- `CbfCalendario::Error`: classe base.

## Uso em Rails (recomendado)

Para produção, use em background com Active Job (ex.: Solid Queue), evitando bloquear requests web:

```ruby
class CbfCalendarioSyncJob < ApplicationJob
  queue_as :default

  def perform(data_iso: nil)
    data = data_iso ? Date.iso8601(data_iso) : Date.current
    CbfCalendario.jogos_pendentes_no_dia(data)
  end
end
```

## Requisitos

- Ruby >= 3.0

## Licença

MIT. Veja `LICENSE.txt`.
# cbf_calendario

Cliente Ruby para a API pública da [CBF](https://www.cbf.com.br): **calendário** (jogos pendentes por dia), **partida** (`/api/cbf/jogos/:id`), **estatísticas derivadas** da súmula e **montagem de URLs** do site. Retornos em **hashes** Ruby para uso em **Rails** ou scripts.

## Instalação

```ruby
# Gemfile
gem 'cbf_calendario', '~> 0.2'
```

```bash
bundle install
```

Em qualquer script Ruby (sem Bundler no load path):

```bash
gem install cbf_calendario
```

```ruby
require 'cbf_calendario'
```

---

## Uso direto (mesmo processo da requisição)

Ideal só para testes ou endpoints muito leves. Para produção, prefira **enfileirar um job** (seção seguinte).

```ruby
require 'cbf_calendario'

# Data como String dd/mm/aaaa, Date ou Time
jogos = CbfCalendario.jogos_pendentes_no_dia('10/05/2026')
# => [{ campeonato: "...", serie: "...", mandante: "...", ... }, ...]

jogos = CbfCalendario.jogos_pendentes_no_dia(Date.current)

# Cliente com opções (timeout HTTP, etc.)
client = CbfCalendario::Client.new(read_timeout: 45)
client.jogos_pendentes_no_dia('01/06/2026')

# Payload bruto da API (Hash) para o dia
client.calendario_json(Date.today)

# Parsing de data brasileira
CbfCalendario.parse_data_br!('25/12/2026') # => Date
```

### Partida (resultado / súmula completa da API)

Mesmo endpoint usado em `show_game.rb`: **`GET /api/cbf/jogos/:id`**. O retorno é o **JSON completo** como `Hash` em Ruby (chaves **string**, igual ao JSON da CBF).

```ruby
# Payload inteiro: tipicamente { "jogo" => { ... registros, atletas, árbitros, ... } }
payload = CbfCalendario.partida_completa('832031')

jogo = payload['jogo']
puts jogo.dig('mandante', 'nome')
puts jogo.dig('mandante', 'gols')
puts jogo.dig('visitante', 'gols')

# Só o objeto jogo (atalho)
jogo = CbfCalendario.jogo_partida(832031)

# Estatísticas derivadas dos registros (gols por tipo, cartões, substituições…)
stats = CbfCalendario.estatisticas_agregadas(jogo)
# => { por_tipo_evento: {...}, gols_mandante_em_eventos: N, ... }

# URLs públicas (mandante/visitante/página da partida), mesma regra do show_game
cp = jogo['campeonato']
ano = (cp['ano'] || jogo['ano']).to_s
pagina = CbfCalendario::Urls.url_pagina_partida(jogo)
mandante_url = CbfCalendario::Urls.url_time(cp['nome'], cp['nome_categoria'], ano, jogo.dig('mandante', 'id'))
```

Timeouts maiores (como no script original):

```ruby
CbfCalendario.partida_completa('832031', read_timeout: 45, open_timeout: 15)
```

Erros extras: `CbfCalendario::InvalidGameIdError` (ID inválido), `CbfCalendario::HttpError` (HTTP ou resposta sem `jogo`).

---

## Referência das funções públicas

### Módulo `CbfCalendario` (atalhos)

| Função | Descrição |
|--------|-----------|
| `parse_data_br!(str)` | Converte `"dd/mm/aaaa"` em `Date`. Lança `InvalidDateError`. |
| `jogos_pendentes_no_dia(data, **opts)` | Jogos do dia **ainda sem placar** na API. `data`: `String` BR, `Date` ou `Time`. Retorna `Array<Hash>` com **chaves símbolo**. `**opts` repassa para `Client.new`. |
| `partida_completa(id_jogo, **opts)` | `GET /api/cbf/jogos/:id` — payload JSON completo. Retorna `Hash` com **chaves string** (como o JSON). |
| `jogo_partida(id_jogo, **opts)` | Mesmo endpoint; retorna só `payload["jogo"]` (`Hash` ou levanta erro se ausente). |
| `estatisticas_agregadas(jogo)` | Agrega eventos da súmula (`registros`, substituições, etc.). Espera o **Hash `jogo`** vindo da API. Retorna `Hash` com **chaves símbolo**. |

### Classe `CbfCalendario::Client`

Construtor: `Client.new(base_url: "https://www.cbf.com.br", read_timeout: 30, open_timeout: 15)`.

| Método | Descrição |
|--------|-----------|
| `jogos_pendentes_no_dia(data)` | Igual ao atalho do módulo. |
| `calendario_json(data)` | Payload bruto do calendário: `GET /api/cbf/calendario/jogos/AAAA/MM/DD` (`Hash`, chaves string). |
| `partida_completa(id_jogo)` | Payload bruto da partida (`GET /api/cbf/jogos/:id`). |
| `jogo_partida(id_jogo)` | Somente o objeto `jogo`. |
| `Client.parse_data_br!(str)` | Igual `CbfCalendario.parse_data_br!`. |
| `Client.coerce_date!(data)` | Normaliza `Date` / `Time` / string `dd/mm/aaaa`. |
| `Client.normalize_id_jogo!(id)` | Valida ID numérico (`String` de dígitos) ou levanta `InvalidGameIdError`. |

### `CbfCalendario::PartidaStats`

| Método | Descrição |
|--------|-----------|
| `agregadas(jogo)` | Implementação central das agregações; mesmo resultado que `CbfCalendario.estatisticas_agregadas(jogo)`. |

Chaves típicas no **retorno** de `estatisticas_agregadas` / `PartidaStats.agregadas`:

| Chave (símbolo) | Conteúdo |
|-----------------|----------|
| `:por_tipo_evento` | Contagem por `tipo` em `registros` (ex.: `GOL`, `PENALIDADE`). |
| `:gols_por_classificacao_sumula` | Contagem por campo `resultado` nos eventos de gol. |
| `:gols_mandante_em_eventos` | Gols do mandante contados nos registros `GOL`. |
| `:gols_visitante_em_eventos` | Idem visitante. |
| `:cartoes_por_resultado` | Contagem por `resultado` em eventos `PENALIDADE`. |
| `:total_substituicoes_mandante` | Quantidade de substituições no mandante. |
| `:total_substituicoes_visitante` | Idem visitante. |

### `CbfCalendario::Urls` (links do site, sem HTTP)

Constante: `CbfCalendario::Urls::SITE_ROOT` (`"https://www.cbf.com.br"`).

| Método | Descrição |
|--------|-----------|
| `slug_segment(str)` | Slug à URL (remove acentos, minúsculas, hífens). |
| `segmento_campeonato(nome)` | Segmento do campeonato na URL (ex.: `campeonato-brasileiro`). |
| `segmento_categoria(nome_serie)` | Segmento da categoria/série (`serie-a`, `sub-20`, etc.). |
| `path_pagina_jogo(jogo)` | Path relativo da página da partida no site. |
| `url_pagina_partida(jogo, base: SITE_ROOT)` | URL absoluta da partida. |
| `url_time(campeonato_nome, categoria_nome, ano, clube_id, base: SITE_ROOT)` | URL da página do clube na temporada. |

O objeto `jogo`/`payload` usado em `Urls` deve ser o **Hash da API** (como em `jogo_partida`), com `campeonato`, `mandante`, `visitante`, `id_jogo`, etc.

---

## Rails: Solid Queue e jobs em background (recomendado)

A API da CBF é chamada via rede; **não bloqueie** requisições HTTP longas no processo web (ex.: Puma). Use **[Solid Queue](https://github.com/rails/solid_queue)** (Rails 8+):

1. Inclua `cbf_calendario` no `Gemfile`.
2. Configure o adapter **`solid_queue`** para o Active Job.
3. Implemente um **Active Job** que chama `CbfCalendario`.
4. Rode o worker **`bin/jobs`** (processo separado do servidor web).

### 1. Adapter Solid Queue

No `Gemfile`, garanta a gem (no Rails 8 costuma vir por padrão; confira o guia do seu app):

```ruby
gem 'cbf_calendario'
gem 'solid_queue'
```

`config/application.rb` (ou ambiente de produção):

```ruby
config.active_job.queue_adapter = :solid_queue
```

Em desenvolvimento e produção, mantenha `config.active_job.queue_adapter = :solid_queue` e rode `bin/jobs` quando precisar processar filas fora do ciclo de request.

### 2. Job com Active Job

`app/jobs/cbf_calendario_sync_job.rb`:

```ruby
# frozen_string_literal: true

class CbfCalendarioSyncJob < ApplicationJob
  queue_as :default

  # data_iso: "2026-05-10" ou nil para usar Date.current
  def perform(data_iso: nil)
    data =
      if data_iso.present?
        Date.iso8601(data_iso.to_s)
      else
        Date.current
      end

    jogos = CbfCalendario.jogos_pendentes_no_dia(data)

    # Exemplo: persistir, notificar, cachear — adapte ao seu domínio
    Rails.logger.info("[CBF] #{jogos.size} jogos pendentes em #{data}")

    jogos.each do |jogo|
      ExternalFixtureUpsertService.call(jogo) # seu serviço
    end

    jogos
  rescue CbfCalendario::HttpError => e
    Rails.logger.error("[CBF] HTTP: #{e.message}")
    raise # deixa o Active Job aplicar retry conforme configuração
  rescue CbfCalendario::InvalidDateError => e
    Rails.logger.warn("[CBF] data inválida: #{e.message}")
    raise
  end
end
```

Enfileirar (controller, outro job, scheduler):

```ruby
# data específica
CbfCalendarioSyncJob.perform_later(data_iso: '2026-05-10')

# “hoje” no servidor
CbfCalendarioSyncJob.perform_later

# com delay
CbfCalendarioSyncJob.set(wait: 5.minutes).perform_later(data_iso: Date.tomorrow.iso8601)
```

### 3. Processar a fila (`bin/jobs`)

Com Solid Queue, o worker padrão processa os jobs enfileirados:

```bash
bin/jobs
```

Rode em **processo separado** do `rails server` / Puma. Em produção, trate `bin/jobs` como serviço (systemd, container, Plataforma como serviço, etc.).

### 4. Agendamento periódico (Solid Queue)

Use o **recurring** do Solid Queue (ex.: `config/recurring.yml` no seu app) para enfileirar `CbfCalendarioSyncJob.perform_later` no horário desejado. A sintaxe e os arquivos exatos dependem da versão do Solid Queue — veja a [documentação do Solid Queue](https://github.com/rails/solid_queue) (seção *Recurring / cron*).

### 5. Serviço systemd (exemplo): `bin/jobs` no ar

Ajuste usuário, path e caminho do Ruby:

```ini
[Unit]
Description=Solid Queue — processador de jobs (Rails + cbf_calendario)
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/var/www/seu_app/current
Environment=RAILS_ENV=production
ExecStart=/home/deploy/.rbenv/shims/bundle exec bin/jobs
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now solid-queue-jobs.service
```

(O nome do arquivo `.service` pode ser o que preferir; o importante é executar `bundle exec bin/jobs`.)

---

## API dos hashes retornados (calendário / pendentes)

A tabela abaixo vale para **cada item** de `jogos_pendentes_no_dia` (chaves **símbolo**). O objeto **`jogo`** de `partida_completa` / `jogo_partida` segue o JSON da CBF (chaves **string**: `"mandante"`, `"registros"`, `"arbitros"`, etc.) — veja a referência completa acima.

| Chave | Significado |
|-------|-------------|
| `:campeonato` | Nome do campeonato |
| `:serie` | Série / divisão |
| `:mandante` | Time mandante |
| `:visitante` | Time visitante |
| `:placar_ou_horario` | Horário previsto ou placar, se houver |
| `:data` | Data como string na API |
| `:data_iso` | Data no formato `YYYY-MM-DD` |
| `:local` | Local do jogo |
| `:rodada` | Rodada |
| `:id_jogo` | Identificador do jogo na CBF |

### Erros

| Classe | Quando |
|--------|--------|
| `CbfCalendario::InvalidDateError` | Data em formato inválido |
| `CbfCalendario::InvalidGameIdError` | ID de jogo não numérico |
| `CbfCalendario::HttpError` | Falha HTTP ao chamar a API |
| `CbfCalendario::Error` | Classe base |

Em jobs, costuma-se **relançar** `HttpError` para retry exponencial; datas inválidas podem ser descartadas sem retry.

### Rails: responder JSON a partir dos hashes

```ruby
def index
  jogos = CbfCalendario.jogos_pendentes_no_dia(params.require(:data))
  render json: jogos.map(&:stringify_keys)
end
```

Para não bloquear o request em produção, prefira só enfileirar o job e devolver `202 Accepted`, ou ler resultado de cache/banco preenchido pelo job.

---

## Requisitos

- Ruby >= 3.0

## Licença

MIT — veja [LICENSE.txt](LICENSE.txt).
