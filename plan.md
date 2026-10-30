# CASTELIONYX — manutenção da versão mais recente

## Escopo

Continuar apenas o clone de `leandrodelima607-maker/castelionyx` no branch `main`. Preservar a arquitetura Godot 2D e o jogo existente; não editar repositórios anteriores nem tratar a URL publicada como cópia editável. Os arquivos de implementação são `catalog.gd` (catálogo), `battle.gd` (simulação), `persistence.gd` (saves locais), `main.gd` (telas/HUD), `world.gd` (renderer) e `tools/castelionyx/check.gd` (testes).

## Compatibilização dos anexos

Os anexos 2 e 3 descrevem o mesmo conjunto de seis desafios com metas, modificadores e recompensas detalhadas. Esse conjunto específico foi implementado: Sobrevivente sem Exército, O Céu Está Caindo, Última Esperança, A Praga Mutante, Mestre da Escassez e O Herói Extra. O anexo 1 apresenta outros cinco conceitos genéricos, sem os detalhes e valores necessários; para não substituir as seis recompensas específicas, eles não foram adicionados como eventos extras nesta rodada. A Primeira Fortuna, requisito não conflitante do anexo 1, foi mantida como um marco adicional: 100 abates acumulados no Infinito liberam permanentemente o Gerador de Moedas.

O pagamento explícito de 50 moedas temporárias por abate prevalece sobre o redutor genérico de 30% do modificador Economia Limitada: esse modificador reduz o ouro inicial e os bônus de onda, sem alterar os 50 por inimigo. A Aventura mantém cinco espaços e apenas Torre de Arqueiros/Canhão; o Infinito normal mantém dez espaços; Exército Reduzido usa cinco nos desafios compatíveis. Evoluções permanentes de heróis, estruturas e feitiços ficam limitadas a 0–4.

## Trabalho integrado

- Rotas sorteadas e visíveis por partida, com caminhos que terminam no castelo, distribuição por rota e máximo de quatro vias; espaços também sorteados, fora das rotas e sem sobreposição.
- Economia temporária idempotente; Gerador por 13 moedas/1 moeda a cada 4 segundos enquanto a partida está ativa; Mina exclusiva por 250 moedas/1 gema a cada 60 segundos de combate ativo, com crédito local imediato idempotente.
- Seis desafios reais com modificadores, progresso por partida válida, recompensas persistentes e entrada pela interface; seleção de até dois heróis após o desbloqueio; Sentinela, Balista, Barreira do Reino e Meteoro Aprimorado integrados ao combate.
- Aventura mais pressionada, nível do jogador calculado somente por ondas do Infinito, Desafio dos Chefes no nível 5 e Sobrevivência Extrema no 24, com registros separados.
- Perfil local com nome/e-mail e validação de formato. Não há autenticação remota ou sincronização; a interface deve preservar esse aviso.
- Indicadores de ciclo de produção do Gerador e da Mina são desenhados continuamente acima das estruturas; não dependem do painel modal, que pausa a simulação.
- Economia Limitada parte de 70% do saldo inicial padrão com arredondamento à moeda inteira mais próxima (425 → 298); os 50 por abate permanecem exatos.

## Áudio e arquivos grandes

A faixa especial referenciada em `assets.lock.json` foi recuperada em uma cópia temporária do armazenamento público e conferida por transcrição: “É inútil, você deve desistir”, com cerca de 0,5 s de pausa entre “inútil” e “você”. As palavras solicitadas já estão na faixa e as outras linhas permanecem intactas; por isso nenhum áudio foi regenerado ou alterado. O clone de GitHub contém os metadados `.import` e o manifesto, enquanto a mídia é hidratada do armazenamento gerenciado.

## Verificação e limite de entrega

A suíte comportamental isolada do Godot passou com **242 testes e 0 falhas**. A cena mínima da interface real também iniciou por três frames sem erros de GDScript/runtime, com imagens/fontes e autoload de áudio substitutos apenas na pasta temporária. Isso não substitui a exportação nem a aceitação em navegador/dispositivo: `tools/verify.sh` exige o `GAME_RUNTIME` emitido por um projeto Webdev anexado e ele não está disponível nesta sessão. A conexão GitHub foi autorizada e o repositório/branch `main` foi confirmado; ainda falta enviar o commit. A versão publicada não foi alterada.
