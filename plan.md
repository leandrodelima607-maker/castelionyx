# CASTELIONYX — implementação

O projeto terá uma simulação 2D autoritativa em Godot, exportada para navegador com uma camada HTML/CSS/JavaScript. Não havia código-fonte no envio: esta é uma implementação nova, e não uma modificação do código original. O idioma será português brasileiro e o perfil/progresso ficarão apenas no armazenamento local do navegador; não haverá conta online, servidor, anúncios ou pagamentos.

## Estrutura

- `scripts/castelionyx/catalog.gd`: definições e balanceamento de seis heróis, seis estruturas, sete inimigos, quatro chefes, cinco feitiços, quatro mapas, seis modificadores e cinco ondas de aventura.
- `scripts/castelionyx/battle.gd`: estados de ondas, fila de geração, combate, unidades, projéteis, feitiços, chefes, simulação baseada em delta time e resultado imutável.
- `scripts/castelionyx/persistence.gd`: validação/migração e gravação local de perfil, níveis, moeda, estatísticas e recompensas uma única vez.
- `scripts/castelionyx/world.gd`: terreno/rotas, sprites originais, efeitos e estados visuais sem autoridade sobre o combate.
- `scripts/main.gd`: telas, HUD, seleção, controles por toque/mouse/teclado, pausa e configurações.
- `autoload/audio_director.gd`: reprodução reutilizando o backend de áudio seguro do navegador, transições e canais independentes.
- `assets/combat`, `assets/kingdom`, `assets/songs`, `assets/cues`: arte e áudio originais gerados e versões compactadas de runtime.
- `web/loading.html`: carregamento real em português, progresso, retry e identidade de Castelionyx.

## Direção visual

Pixel art de estratégia medieval: contornos escuros, aço e telhados azuis, campos verde-musgo, florestas azul-petróleo e detalhes dourados. Personagens e edifícios usam os sprites originais produzidos; caminhos e terrenos complementares são desenhados em pixels. A interface usa painéis escuros e ouro, tipografia legível e controles amplos. O campo se ajusta ao espaço disponível e, no retrato, controles ficam abaixo dele em vez de cobri-lo.

## Áudio

Música não será substituída por osciladores. As gerações solicitam voz cantada em português e composição original. Letras exatas não são garantidas pela ferramenta. A batalha é planejada em duas partes diferentes para superar cinco minutos, com crossfade; não se repete um trecho curto para simular a duração. Uma geração de continuação falhou e a autorização para nova tentativa foi solicitada. A derrota gerada excedeu a duração pedida; a adequação será descrita com transparência após verificar o arquivo. Efeitos são arquivos próprios separados, gerados ou sintetizados como SFX, jamais como substitutos das músicas.

## Regras centrais

Ondas só terminam com fila vazia e zero inimigos vivos. Chefes não são saltados. Ataques terrestres não atingem voadores. Gêmeos têm duas entidades e vidas próprias. Guardas/invocações têm vida, escudo, limite e duração. Freeze tem resistência e imunidade temporária, suporte não acumula sem limite. Melhorias afetam atributos. A aventura tem exatamente cinco ondas e recompensa integral uma única vez após vitória. Infinito concede `floor(completas/10)` ao encerrar, sem duplicação. O resultado separa concluídas de onda de derrota.
