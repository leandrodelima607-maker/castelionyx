class_name CxCatalog
extends RefCounted

const HEROES = [
 {"id":"guardian","name":"Guardião","sprite":0,"hp":260.0,"damage":30.0,"interval":0.9,"range":48.0,"speed":115.0,"air":false,"armor":0.3,"cost":0,"cooldown":14.0,"skill":"Investida Real","desc":"Equilibrado. Bloqueia ataques frontais e investe contra os invasores."},
 {"id":"archer","name":"Arqueiro Celeste","sprite":1,"hp":155.0,"damage":25.0,"interval":0.65,"range":180.0,"speed":130.0,"air":true,"armor":0.0,"cost":2,"cooldown":16.0,"skill":"Flecha Perfurante","desc":"Flechas luminosas alcançam voadores. O especial perfura uma linha de alvos."},
 {"id":"twins","name":"Gêmeos Furiosos","sprite":2,"hp":115.0,"damage":19.0,"interval":0.42,"range":43.0,"speed":140.0,"air":false,"armor":0.0,"cost":4,"cooldown":16.0,"skill":"Combo dos Gêmeos","desc":"Dois guerreiros com vidas próprias. Combo acelera e reforça os golpes."},
 {"id":"iron","name":"Cavaleiro de Ferro","sprite":4,"hp":450.0,"damage":28.0,"interval":1.45,"range":55.0,"speed":86.0,"air":false,"armor":0.55,"cost":6,"cooldown":18.0,"skill":"Golpe Sísmico","desc":"Muito resistente. Atrai terrestres próximos e os empurra com um golpe pesado."},
 {"id":"ice","name":"Mago Glacial","sprite":5,"hp":150.0,"damage":18.0,"interval":1.05,"range":165.0,"speed":105.0,"air":true,"armor":0.0,"cost":8,"cooldown":20.0,"skill":"Inverno Absoluto","desc":"Projéteis aplicam lentidão. O especial congela um grupo por tempo limitado."},
 {"id":"summoner","name":"Invocador","sprite":6,"hp":160.0,"damage":22.0,"interval":1.1,"range":165.0,"speed":100.0,"air":true,"armor":0.0,"cost":10,"cooldown":24.0,"skill":"Pacto Violeta","desc":"Invoca três aliados mágicos com vida própria e duração de 18 segundos."}
]
const TOWERS = [
 {"id":"arrow","name":"Torre de Arqueiros","sprite":0,"cost":100,"hp":220.0,"damage":28.0,"interval":0.72,"range":155.0,"air":true,"desc":"Flechas rápidas; acerta terrestres e aéreos."},
 {"id":"cannon","name":"Canhão","sprite":1,"cost":150,"hp":280.0,"damage":52.0,"interval":1.7,"range":160.0,"air":false,"desc":"Explosão em área de 58 pixels. Apenas terrestres."},
 {"id":"frost","name":"Torre Glacial","sprite":2,"cost":125,"hp":195.0,"damage":9.0,"interval":2.6,"range":150.0,"air":true,"desc":"Gelo por 2s com resistência e imunidade após o efeito."},
 {"id":"electric","name":"Torre Elétrica","sprite":3,"cost":175,"hp":200.0,"damage":23.0,"interval":1.25,"range":145.0,"air":true,"desc":"Saltos elétricos entre 2 a 4 invasores próximos."},
 {"id":"barracks","name":"Quartel","sprite":4,"cost":120,"hp":300.0,"damage":13.0,"interval":7.0,"range":145.0,"air":false,"desc":"Produz até 2–4 cavaleiros vivos que interceptam terrestres."},
 {"id":"support","name":"Santuário de Suporte","sprite":5,"cost":160,"hp":230.0,"damage":0.0,"interval":1.0,"range":170.0,"air":false,"desc":"+25% de cadência e +15% de alcance nas defesas próximas. Não acumula."}
]
const SPELLS = [
 {"id":"meteor","name":"Meteoros","short":"Meteoro","cooldown":30.0,"duration":1.0,"desc":"Marque uma área: 3 meteoros causam dano em área após 0,8s."},
 {"id":"prison","name":"Prisão Glacial","short":"Gelo","cooldown":24.0,"duration":4.0,"desc":"Congela inimigos em área por 4s; chefes resistem parcialmente."},
 {"id":"barrier","name":"Barreira Real","short":"Barreira","cooldown":35.0,"duration":9.0,"desc":"Reduz 80% do dano ao castelo durante 9s."},
 {"id":"chain","name":"Corrente Elétrica","short":"Raio","cooldown":22.0,"duration":0.5,"desc":"Atinge até 5–7 alvos conectados, com dano real por salto."},
 {"id":"guards","name":"Invocação Emergencial","short":"Guardas","cooldown":32.0,"duration":20.0,"desc":"Três guardas com escudo quebrável, vida própria e duração de 20s."}
]
const ENEMIES = [
 {"id":"common","name":"Goblin","sprite":0,"hp":46.0,"speed":48.0,"damage":9.0,"reward":12,"armor":0.0,"air":false},
 {"id":"runner","name":"Corredor","sprite":1,"hp":33.0,"speed":83.0,"damage":7.0,"reward":12,"armor":0.0,"air":false},
 {"id":"brute","name":"Bruto","sprite":2,"hp":180.0,"speed":30.0,"damage":24.0,"reward":23,"armor":0.25,"air":false},
 {"id":"flyer","name":"Voador","sprite":3,"hp":55.0,"speed":59.0,"damage":10.0,"reward":15,"armor":0.0,"air":true},
 {"id":"gunner","name":"Artilheiro","sprite":4,"hp":90.0,"speed":36.0,"damage":15.0,"reward":20,"armor":0.1,"air":false},
 {"id":"regen","name":"Regenerador","sprite":5,"hp":155.0,"speed":39.0,"damage":17.0,"reward":24,"armor":0.1,"air":false},
 {"id":"mutant","name":"Mutante","sprite":6,"hp":108.0,"speed":48.0,"damage":14.0,"reward":24,"armor":0.05,"air":false},
 {"id":"skeleton","name":"Esqueleto","sprite":7,"hp":38.0,"speed":55.0,"damage":7.0,"reward":6,"armor":0.0,"air":false}
]
const BOSSES = [
 {"id":"barbarian","name":"Rei Bárbaro","sprite":8,"hp":1100.0,"speed":24.0,"damage":65.0,"reward":180,"armor":0.18,"air":false},
 {"id":"dragon","name":"Dragão Cinzento","sprite":9,"hp":1200.0,"speed":31.0,"damage":70.0,"reward":210,"armor":0.12,"air":true},
 {"id":"titan","name":"Titã de Ferro","sprite":10,"hp":1650.0,"speed":18.0,"damage":100.0,"reward":250,"armor":0.38,"air":false},
 {"id":"necro","name":"Necromante","sprite":11,"hp":1300.0,"speed":22.0,"damage":65.0,"reward":260,"armor":0.1,"air":false}
]
const MAPS = [
 {"id":"serpent","name":"Caminho da Serpente","tag":"ROTAS SINUOSAS","desc":"Curvas longas e muitos pontos de defesa. Equilibrado para começar.","ground":[[Vector2(-35,160),Vector2(160,160),Vector2(160,325),Vector2(375,325),Vector2(375,155),Vector2(595,155),Vector2(595,405),Vector2(815,405),Vector2(815,285),Vector2(945,285)]],"air":[Vector2(-35,70),Vector2(340,240),Vector2(660,80),Vector2(945,285)],"pads":[Vector2(95,235),Vector2(230,230),Vector2(280,405),Vector2(305,135),Vector2(470,235),Vector2(535,350),Vector2(685,230),Vector2(735,475),Vector2(760,305),Vector2(890,385)]},
 {"id":"bridge","name":"Ponte do Cerco","tag":"PRESSÃO DE GRUPOS","desc":"Uma ponte estreita. Só seis posições; grupos 25% maiores.","ground":[[Vector2(-35,285),Vector2(240,285),Vector2(420,220),Vector2(650,220),Vector2(795,285),Vector2(945,285)]],"air":[Vector2(-35,100),Vector2(420,140),Vector2(945,285)],"pads":[Vector2(155,205),Vector2(330,350),Vector2(460,135),Vector2(590,320),Vector2(735,185),Vector2(850,390)]},
 {"id":"sky","name":"Ilhas Celestes","tag":"AMEAÇA AÉREA","desc":"Plataformas entre nuvens. Voadores frequentes e caminho terrestre curto.","ground":[[Vector2(-35,365),Vector2(230,365),Vector2(380,285),Vector2(620,285),Vector2(780,365),Vector2(945,285)]],"air":[Vector2(-35,90),Vector2(240,160),Vector2(440,65),Vector2(700,170),Vector2(945,285)],"pads":[Vector2(100,285),Vector2(250,240),Vector2(360,390),Vector2(490,180),Vector2(610,395),Vector2(720,235),Vector2(855,200)]},
 {"id":"forest","name":"Floresta Amaldiçoada","tag":"DUAS ROTAS","desc":"Ruínas e árvores sombrias. Invasores chegam pelos dois caminhos.","ground":[[Vector2(-35,125),Vector2(210,125),Vector2(330,275),Vector2(570,275),Vector2(730,160),Vector2(945,285)],[Vector2(-35,420),Vector2(210,420),Vector2(330,275),Vector2(570,275),Vector2(730,415),Vector2(945,285)]],"air":[Vector2(-35,250),Vector2(500,110),Vector2(945,285)],"pads":[Vector2(155,230),Vector2(180,330),Vector2(315,125),Vector2(405,390),Vector2(490,195),Vector2(610,405),Vector2(665,220),Vector2(825,305)]}
]
const MODIFIERS = [
 {"id":"reduced","name":"Exército Reduzido","desc":"Metade dos espaços; +25% inimigos. Gemas-base sem bônus."},
 {"id":"nohero","name":"Sem Heróis","desc":"Nenhum herói em campo. Feitiços e estruturas continuam disponíveis."},
 {"id":"aerial","name":"Cerco Aéreo","desc":"Um invasor a cada três será voador. Prepare antiaéreo."},
 {"id":"economy","name":"Economia Limitada","desc":"-30% ouro inicial e recebido. Recompensa-base preservada."},
 {"id":"wall","name":"Última Muralha","desc":"Castelo começa com metade da vida."},
 {"id":"mutants","name":"Inimigos Mutantes","desc":"Um inimigo a cada quatro tem escudo que quebra e acelera."}
]
const ADVENTURE_NAMES = ["Enxame","Velocidade","Céu e Terra","Resistência","Chefe Final"]

static func hero(index:int,level:int=1) -> Dictionary:
 var d=HEROES[clampi(index,0,5)].duplicate(true)
 d.hp *= 1.0+0.12*(level-1)
 d.damage *= 1.0+0.15*(level-1)
 d.cooldown *= maxf(0.65,1.0-0.04*(level-1))
 return d

static func tower(index:int,level:int=1,persistent:int=1) -> Dictionary:
 var d=TOWERS[clampi(index,0,5)].duplicate(true)
 d.hp *= 1.0+0.25*(level-1)
 d.damage *= (1.0+0.48*(level-1))*(1.0+0.06*(persistent-1))
 d.range += 10.0*(level-1)
 d.interval *= maxf(0.7,1.0-0.1*(level-1))
 return d

static func upgrade_cost(tower_index:int,level:int) -> int:
 return int(TOWERS[tower_index].cost*(0.75+0.4*level))

static func path_length(points:Array) -> float:
 var total=0.0
 for i in range(1,points.size()): total+=points[i-1].distance_to(points[i])
 return total

static func path_position(points:Array,distance:float) -> Vector2:
 var remaining=maxf(distance,0.0)
 for i in range(1,points.size()):
  var length=points[i-1].distance_to(points[i])
  if remaining<=length: return points[i-1].lerp(points[i],remaining/maxf(length,0.01))
  remaining-=length
 return points[-1]

static func nearest_ground(map_index:int,point:Vector2) -> Vector2:
 var best=Vector2(815,285)
 var dist=INF
 for route in MAPS[map_index].ground:
  for i in range(1,route.size()):
   var candidate=Geometry2D.get_closest_point_to_segment(point,route[i-1],route[i])
   var delta=point.distance_squared_to(candidate)
   if delta<dist:
    dist=delta
    best=candidate
 return Vector2(clampf(best.x,10,905),clampf(best.y,65,505))
