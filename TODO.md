# CASTELIONYX — estado da rodada de correções

## Concluído no worktree local de `leandrodelima607-maker/castelionyx` (branch `main`)

- [x] Rotas terrestres/área sorteadas a cada partida, visualizadas no mapa, distribuindo os inimigos e convergindo ao castelo; máximo de quatro vias. Posições de construção sorteadas junto com as rotas, fora dos caminhos e sem sobreposição.
- [x] Exatamente 5 espaços na Aventura, 10 no Infinito comum e 5 com Exército Reduzido; moedas temporárias não viram gemas automaticamente. Cada abate válido dá 50 moedas uma vez.
- [x] Gerador de Moedas permanente após marco de 100 abates no Infinito; custa 13 moedas, produz uma a cada quatro segundos enquanto a partida está ativa, pausa com a partida e para se removido/destruído. Uma barra de progresso avança sobre a estrutura.
- [x] Mina de Gemas exclusiva do Mestre da Escassez; custa 250 moedas, ocupa espaço vulnerável e produz uma gema por 60 segundos de combate. O saldo local é atualizado durante a partida de forma idempotente, a produção para em pausa/fim/destruição e a barra de progresso permanece visível no campo.
- [x] Seis eventos detalhados dos anexos 2–3, com modificadores reais, metas em uma partida, progresso persistido, recompensas exclusivas e entrada pela tela de Eventos. Metas atingidas antes de uma derrota posterior contam; progresso abaixo da meta não concede a recompensa.
- [x] Sentinela Arcana (1,5 s, longo alcance, terra/ar, Marca Arcana e Explosão Rúnica automática em 20 s); Balista Celeste (180 moedas, preferência aérea, perfuração no 4º disparo, sem acelerar acima de 2,5 s); Barreira do Reino (120 moedas, 6 s, 60% de redução, recarga de 45 s); Meteoro Aprimorado (+25% dano/+15% área, sem usos extras).
- [x] Segundo espaço de herói desbloqueável, escolha sem duplicatas, entrada real dos dois heróis e respeito a Sem Heróis/Aventura.
- [x] Evoluções permanentes 0–4; feitiços de 300–500 gemas e heróis/estruturas a partir de 3.600; nível do jogador apenas por ondas do Infinito; modos dos níveis 5/24 com estatísticas separadas.
- [x] Aventura com ondas e chefe final mais difíceis, cinco espaços e apenas Torre de Arqueiros/Canhão; eventos e regras dos outros modos permanecem separados.
- [x] Campo de país substituído por e-mail com validação. Perfil/progresso seguem locais; não existe sincronização nem recuperação remota sem autenticação/backend.
- [x] A faixa de derrota especial já contém “É inútil, você deve desistir” com uma pausa de aproximadamente 0,5 s após “inútil”. As demais linhas foram preservadas; nenhum áudio novo nem palavras extras foram adicionados.
- [x] Economia Limitada começa com 70% do saldo padrão arredondado para a moeda inteira mais próxima (425 × 70% = 297,5, arredondados para 298); o bônus de onda aplica o fator 70% e o pagamento de abate continua fixo em 50.
- [x] `tools/castelionyx/check.gd`: **242 passaram, 0 falharam** no projeto temporário isolado. Cena de UI real carregou por três frames sem erro de parser/runtime. `git diff --check` sem erros.

## Pontos que ainda precisam de uma decisão ou acesso

- [ ] **Lista alternativa do anexo 1:** Muralha Impossível, Caçador de Gigantes, Defesa Econômica, Reino Sem Heróis e Provação de Castelionyx não são as seis recompensas detalhadas dos anexos 2–3. Não foram acrescentados nesta rodada para evitar inventar metas/recompensas ou substituir o conjunto específico. Confirmar se devem virar cinco desafios adicionais.
- [ ] **Validação oficial/exportação:** `tools/verify.sh` parou com “Set GAME_RUNTIME to the Game runtime directory returned by init/attach.” Falta o runtime oficial; o check temporário não é build/export completo nem aceitação no navegador/Android.
- [ ] **GitHub:** conexão autorizada e acesso de leitura ao repositório/branch `main` confirmados. Ainda falta criar commit e enviar este worktree; não houve push até este ponto.
- [ ] **Publicação:** a URL `castelionyx-mrgftfuz.manus.game` não foi atualizada nesta rodada. Só declarar isso depois do fluxo oficial de build/checkpoint/publicação e confirmação da nova versão.

## Resolução de especificações sobrepostas

O anexo 1 traz uma lista alternativa de seis eventos, enquanto os anexos 2 e 3 concordam nos seis eventos detalhados. Foram preservados os seis específicos dos anexos 2–3 e o requisito não conflitante “A Primeira Fortuna” virou marco adicional de 100 abates para liberar o Gerador. Os outros cinco conceitos genéricos permanecem aguardando confirmação caso devam existir como desafios adicionais.
