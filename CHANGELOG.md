# Changelog

## [0.4.1] - 2026-05-11

- Renomeação: `jogos_pendentes_no_dia` → `jogos_do_dia` em `CbfCalendario` e `CbfCalendario::Client` (sem alias)

## [0.4.0] - 2026-05-11

- `Client#jogos_pendentes_no_dia` / `CbfCalendario.jogos_pendentes_no_dia`: passa a listar **todos** os jogos do dia (não só os sem placar na API)
- Cada linha inclui `placar` (`"M x V"` quando mandante e visitante têm `gols` na API; caso contrário `nil`) além de `horario`
- README e gemspec atualizados para refletir o novo comportamento

## [0.3.3] - 2026-05-11

- Suíte de testes Minitest completa no padrão Rails (`test/`) cobrindo módulo principal, `Client`, `PartidaStats` e `Urls`
- `Rakefile` com task `rake test` para execução local da suíte
- CI no GitHub Actions (`.github/workflows/test.yml`) para rodar testes em push/PR nas versões Ruby 3.2, 3.3 e 3.4
- Dependências de desenvolvimento adicionadas: `rake` e `minitest (~> 5.22)`

## [0.3.2] - 2026-05-11

- Ajustes internos de robustez HTTP no cliente
- Suporte a redirecionamentos HTTP (ex.: 308) nas requisições internas do cliente
- README atualizado

## [0.3.1] - 2026-05-11

- `Client#jogos_pendentes_no_dia`: chave renomeada de `placar_ou_horario` para `horario`
- README atualizado para refletir o novo formato de retorno dos jogos pendentes

## [0.3.0] - 2026-05-11

- Melhorias incrementais no cliente HTTP e na documentação
- README simplificado e atualizado com as novas funções e exemplos de retorno

## [0.2.0] - 2026-05-10

- `Client#partida_completa` / `Client#jogo_partida` — API `/api/cbf/jogos/:id` (mesmo escopo de dados que `show_game.rb`)
- `CbfCalendario.estatisticas_agregadas(jogo)` e `CbfCalendario::PartidaStats`
- `CbfCalendario::Urls` — paths e URLs da página da partida e dos times
- `InvalidGameIdError`; cliente com `open_timeout`

## [0.1.0] - 2026-05-10

- Primeira publicação no RubyGems
- `CbfCalendario::Client` com `jogos_pendentes_no_dia` e `calendario_json`
- Atalhos no módulo `CbfCalendario`
