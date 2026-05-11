# Changelog

## [0.3.2] - 2026-05-11

- `Client#clube_por_id`: fallback para página pública de times quando endpoints `/api/cbf/clubes/*` e `/api/cbf/times/*` retornam 404
- Suporte a redirecionamentos HTTP (ex.: 308) nas requisições internas do cliente
- README atualizado com exemplo de retorno de `clube_por_id` incluindo contexto e atletas

## [0.3.1] - 2026-05-11

- `Client#jogos_pendentes_no_dia`: chave renomeada de `placar_ou_horario` para `horario`
- README atualizado para refletir o novo formato de retorno dos jogos pendentes

## [0.3.0] - 2026-05-11

- `Client#atletas_do_clube` e atalho `CbfCalendario.atletas_do_clube`
- `Client#atleta_por_id` e atalho `CbfCalendario.atleta_por_id`
- `Client#clube_por_id` e atalho `CbfCalendario.clube_por_id`
- Novos erros de validação: `InvalidClubIdError` e `InvalidAthleteIdError`
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
