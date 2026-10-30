# CASTELIONYX — Defesa do Reino

Esta é uma implementação nova e jogável de defesa de castelo em Godot 2D, exportável para navegador. O envio continha especificações, mas não o código-fonte mencionado. Não é um único HTML: o jogo web usa HTML, JavaScript, WASM e PCK. O jogo não possui login, anúncios, compras, servidor de partidas ou sincronização online. O perfil e o progresso ficam no armazenamento local do navegador.

## Jogar

Use a Preview do projeto no Manus. No computador, o pacote web pode ser servido por qualquer servidor estático: entre na pasta `jogo-web`, execute `python3 -m http.server 8000` e abra `http://localhost:8000`. Navegadores normalmente não permitem carregar WASM/PCK por `file://`, então clicar diretamente no HTML baixado pode falhar. O gameplay não chama serviços externos. O pacote contém os recursos locais necessários; a Preview remota exige conexão para o carregamento inicial. Não foi implementado um instalador Android nem um PWA com cache offline garantido.

Na primeira abertura, toque em criar conta local para liberar o áudio e criar o perfil. Depois, escolha Jogar ou Aventura. Toque nas placas de pedra para construir, melhorar ou vender. Toque na rota para mover o herói. Escolha um feitiço e toque na área; Barreira é imediata. H ativa a habilidade, 1–5 escolhem feitiços, Espaço inicia a onda e Esc pausa/cancela. WASD movimenta o herói. Os botões funcionam por mouse e toque; o campo usa controles laterais no landscape e controles abaixo no retrato.

## Conteúdo implementado

Seis heróis distintos, incluindo dois Gêmeos simultâneos; seis estruturas com construção, custo, vida, melhorias de partida e progressão; cinco feitiços com recarga e efeitos reais; sete arquétipos inimigos e quatro chefes; quatro mapas com rotas diferentes, incluindo aéreas e múltiplas; seis modificadores; defesa infinita; aventura de cinco ondas; perfil, loja de melhorias, estatísticas e configurações locais. Ondas têm fila de geração e contagem de vivos. O resultado separa ondas completas da onda da derrota. Gemas de infinito são `floor(completas/10)`. A conclusão integral da aventura paga 1.000 gemas uma única vez.

Os sprites de personagens, inimigos, estruturas, castelo, reino e capa foram gerados originalmente em pixel art. Arquivos de runtime foram reduzidos com nearest-neighbour mantendo transparência e proporção. Terrenos complementares, rotas e efeitos são desenhados em pixels pelo renderer. Há efeitos de ataque, dano, freeze, escudo, invocação e destruição associados a eventos da simulação. Os cinco feitiços agora usam ícones ilustrados originais transparentes, ligados aos botões reais e também à coleção. As animações são simples transformações/efeitos de estado; **não são spritesheets completas de animação quadro a quadro**.

## Canções e efeitos reais

As três músicas foram geradas como gravações cantadas em português brasileiro e integradas em canais separados dos SFX e da interface. A transcrição dos masters reconheceu vocal em português e versos próprios adequados aos temas. Isso não substitui a avaliação auditiva no aparelho final.

| Faixa | Duração integrada | Situação |
| --- | ---: | --- |
| Abertura | 63,8s | Canção original de convite para criar o perfil e defender o reino |
| Batalha | 334,8s | Rock/orquestra épico cantado, com seção intensa real usada nos chefes |
| Derrota normal | 43,1s | Faixa anterior restaurada; usada em derrotas comuns |
| Derrota especial | 17,0s | Usada somente após o timeout de 25 minutos da décima progressão da Aventura |

Uma segunda parte original foi gerada com voz em português brasileiro, unida à primeira por crossfade de 4 segundos e medida em 334,8s — acima dos cinco minutos solicitados sem repetir artificialmente um trecho curto. A faixa funciona em loop durante a partida sem reiniciar a cada onda. A intensificação de chefe desloca a reprodução para o clímax real da parte estendida e retorna à posição anterior depois. A derrota normal usa novamente a gravação anterior; a vinheta curta `music.defeat_special` contém somente “é inútil...você deve desistir” nesse trecho, sem acrescentar palavras. Ela só é chamada quando o resultado traz `special_defeat=true`, ativado após 150 segundos na progressão da décima Aventura; derrotas infinitas normais não chamam essa faixa.

## Atualização desta rodada

Foram implementados e testados: separação das duas músicas de derrota; derrota especial condicionada à décima progressão da Aventura; derrota normal preservada; e-mail no perfil local no lugar do rótulo de país; moedas de combate de 50 por inimigo derrotado; seleção aleatória de espaços de construção com 5 na Aventura e 10 no Infinito quando o mapa permite; Aventura sem heróis; inimigos extras por vitória da Aventura; persistência de vitórias, nível por ondas acumuladas e seção funcional de eventos com progresso por modificadores.

Os seis eventos registram progresso persistente conforme condições reais e agora concedem as recompensas nas coleções: Sentinela Arcana, Balista Celeste, Barreira do Reino, Meteoro Aprimorado, Mina de Gemas e Segundo espaço de herói. A Mina produz gemas durante a partida e para imediatamente quando destruída; a Balista prioriza voadores com disparo perfurante; a Barreira do Reino cobra 120 moedas e protege por seis segundos; o Meteoro Aprimorado aplica 25% de dano e 15% de área adicionais; e a Sentinela possui marca de cinco ataques e Explosão Rúnica de 20 segundos. Depois do sexto evento, dois heróis selecionados aparecem simultaneamente nos modos compatíveis, sem duplicatas e sem uso na Aventura ou em Sem Heróis. Autenticação remota por e-mail continua não implementada: o projeto permanece com salvamento local e não simula sincronização entre dispositivos.

Na Aventura, o jogo cria exatamente cinco espaços, não cria heróis, bloqueia estruturas que não sejam Torre de Arqueiros ou Canhão e exige a eliminação de todos os inimigos previstos. As cinco ondas são distintas: Enxame, Velocidade, Céu e Terra, Resistência e Chefe Final. O chefe final tem três fases e chama reforços limitados nas transições; a vitória só fecha quando o chefe e esses reforços acabam. A primeira vitória paga 1.000 gemas, cada vitória da segunda à nona tentativa paga 500, e a décima vitória paga exatamente 6.742 gemas sem depender do tempo da partida. A décima tentativa é uma variante estendida com chefes e reforços adicionais.

## Modos secundários e novo catálogo

Além da Defesa infinita e da Aventura, a tela **Modos** agora possui três regras próprias. **Castelo de Um HP** começa com um único ponto de vida, coloca um chefe por onda, alterna entre sete chefes (incluindo Rainha da Tempestade, Colosso de Cristal e Serpe do Firmamento) e termina na onda 67, pagando 6.700 gemas. **Construção até a Onda 101** entrega 1.000 moedas antes do combate, não cria herói nem permite feitiços, permite construir livremente na preparação e dá +25% de alcance às estruturas; depois de iniciar a primeira onda, o botão de construção some e restam apenas pausa e 2x. A conclusão na onda 101 paga 10.101 gemas. **Enxame Duplicado** usa um herói e exatamente três feitiços escolhidos, tem apenas Goblins, começa com 10 inimigos e dobra a quantidade a cada onda, duplica a vida do castelo e conclui na onda 12, pagando 2.400 gemas.

O catálogo também inclui o Ceifador dos Dois Machados (95 HP, 650 de dano por machado, ataque duplo, dano dobrado contra voadores e salto de área), o Mestre das Feras e o Oráculo Solar; Muralha de Espinhos e Torre do Arco Longo; Companhia de Arqueiros, Golem de Pedra (34 s de recarga e 54 s de duração), Fúria de Batalha e Parede de Mato. Os feitiços adicionais começam bloqueados e são comprados com gemas, enquanto Meteoros e Invocação Emergencial continuam sendo as opções iniciais. Nenhuma dessas novidades reutiliza congelamento, choque elétrico ou barreira temporária como efeito principal.

## Onboarding, visuais e economia inicial

Cada perfil novo recebe exatamente 100 gemas uma única vez, com salvamento atômico; editar o perfil não repete o brinde. Depois de concluir o cadastro, o tutorial de quatro instruções aparece uma única vez: mover o herói por toque/WASD, construir em espaços, mirar feitiços e pausar/usar 2x. A última tela diz “Você está pronto!” e leva ao menu; `tutorial_seen` impede a repetição. Perfis antigos são migrados sem apagar progresso.

O **Enxame Duplicado** agora tem um seletor de herói próprio, aplica a escolha antes de criar as entidades da partida e só aceita exatamente três feitiços desbloqueados. A batalha mantém dez cooldowns de feitiços, não apenas os cinco/seis antigos. **Construção até a Onda 101** começa com 9.999 moedas.

O **Ninho do Falcão** custa 1.700 moedas e libera um falcão a cada cinco segundos. Os falcões são aliados aéreos permanentes, atacam inimigos terrestres e aéreos e não desaparecem pelo tempo de vida. A **Torre do Arco Longo** tem alcance extremo, ataque muito rápido e dano baixo. O Ceifador, o Mestre das Feras e o Oráculo Solar possuem silhuetas pixel-art distintas no campo: machados duplos, lobo de guerra e halo/bastão solar, sem depender do mesmo recorte visual do atlas.

## Economia e modos

Heróis, estruturas e feitiços não começam todos desbloqueados. O Guardião, as duas primeiras estruturas e o Meteoro são a base; os demais itens compráveis usam custos progressivos de 3.600 a 88.000 gemas para heróis/estruturas e 300 a 500 gemas para feitiços. Recompensas de eventos são separadas das compras e não podem ser compradas por engano. O menu **Modos** inclui Desafio dos Chefes (chefes adicionais a cada cinco ondas) e Sobrevivência Extrema (economia limitada, mutantes, cerco aéreo, espaços reduzidos e inimigos reforçados), com níveis mínimos aplicados de verdade.

Cada nova partida gera uma variação válida das rotas terrestres e aéreas e sorteia novamente os espaços de construção. A Aventura usa exatamente cinco espaços; os demais modos usam dez, ou cinco quando o modificador Exército Reduzido está ativo. O validador evita sobreposição dos espaços e mantém as rotas conectadas ao castelo; os mesmos dados sorteados são usados pela simulação e pelo renderer.

Sete SFX foram gerados em áudio: construção, canhão, explosão, gelo, eletricidade, invocação e entrada de chefe. Outros seis efeitos curtos foram sintetizados para interface, flecha, moeda, dano ao castelo, melhoria e vitória. Esses efeitos não substituem nenhuma música. Volumes de música, efeitos e interface são separados. O áudio exige um gesto do usuário no navegador.

## Evidência executada

A engine abriu a cena real sem erros de parser/runtime no boot headless. Um script finito executou 92 verificações que passaram: fila/vivos sem avanço prematuro, construir com e sem saldo, ocupar slot, melhoria de dano, regras antiaéreas e rota aérea, os cinco feitiços, recargas, freeze sem acumulação ilimitada, três guardas, absorção/quebra de escudo, dano de meteoro, cura interrompível, propriedade do mutante, dois Gêmeos/combos, invocações expiradas, 2x/pausa, agenda de chefes nas ondas 1–40, conclusão de cinco ondas, salvamento/reabertura de perfil, recompensa integral de aventura, idempotência, fórmula de gemas, contagem da derrota e bloqueio de seleção de herói.

Uma simulação adicional realizou **ações válidas de construção/melhoria, movimentação, habilidade e feitiços com ouro realmente recebido**, chegando a dez ondas completas de infinito com um chefe derrotado e às cinco ondas completas de aventura com o chefe final derrotado. Isso demonstra o ciclo de gameplay; não é prova de balanceamento final para jogadores humanos.

Foram renderizadas e inspecionadas capturas nativas reais do menu, combate e melhoria em 1280×720, além de viewport estreito 390×844. Um problema de campo pequeno/controle cortado no desktop foi corrigido; a nova captura de combate mostra os cinco ícones e os efeitos reforçados sem erros de runtime. O micro-polimento mais recente adiciona setas animadas indicando a direção das rotas terrestre/aérea, barras de vida com moldura e alerta crítico, halo pulsante no castelo sob risco e faíscas nos pontos de derrota. A Preview foi exportada pelo runtime atual, seu endpoint HTTP respondeu, o pacote portátil gerou `dist/standalone/index.pck` e a verificação de pacote passou.

**Não foram testados diretamente:** audibilidade/transições em um navegador real, teclado virtual/galeria/fullscreen do Android, input touch em aparelho físico, instalação/PWA offline, todas as telas em cada combinação de viewport, nem todas as ondas avançadas em partida humana. O renderer nativo foi executado com áudio Dummy para a revisão visual. Testes de simulação e transcrições não serão apresentados como testes auditivos ou Android concluídos.

## Limites adicionais da versão parcial

Faltam refinamento visual de animações quadro a quadro, cenário mais elaborado em todos os mapas, balanceamento fino das ondas tardias e revisão humana de áudio/input no navegador. As melhorias de estruturas alteram tamanho/marcadores/atributos, não todas as peças de uma nova sprite por nível. O bloqueio do Guardião é redução de dano simplificada, não um sistema direcional detalhado de escudo. A validação aceita saves legados compatíveis, mas não existe um migrador específico para o código original ausente. As estatísticas ainda não oferecem filtros separados de infinito e aventura.

A versão é funcional, mas **não deve ser descrita como cumprimento integral de todo o prompt mestre**.

### Correção do cadastro

O formulário agora aceita teclado e toque normalmente: a camada de interface não bloqueia mais os filhos, o campo de nome recebe foco automaticamente na criação, ambos os campos têm foco explícito e a mensagem de erro devolve o foco ao campo de nome quando necessário. O nome/apelido e um e-mail válido são obrigatórios. O e-mail é validado por formato básico e fica salvo somente no perfil local; ele não é enviado a servidor, não cria conta remota e não recupera o progresso em outro dispositivo. Saves antigos sem e-mail continuam com o progresso, mas reabrem o cadastro para que o e-mail seja preenchido antes de entrar no reino.
