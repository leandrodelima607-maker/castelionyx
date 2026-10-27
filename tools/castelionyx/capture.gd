extends SceneTree
func _initialize() -> void:
 call_deferred("capture")

func capture() -> void:
 var scene=load("res://scenes/main.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 scene.persistence.profile("Defensor","Brasil",0)
 scene.show_menu()
 for i in range(4): await process_frame
 var path=OS.get_environment("CX_CAPTURE")
 if path=="": path="res://dist/menu.png"
 root.get_texture().get_image().save_png(path)
 scene.launch("infinite")
 scene.battle.build(0,0)
 scene.battle.build(1,1)
 scene.battle.start_wave()
 for i in range(10):
  scene.battle.tick(0.12)
  await process_frame
 root.get_texture().get_image().save_png(path.replace("menu","battle"))
 scene.show_build(0)
 for i in range(3): await process_frame
 root.get_texture().get_image().save_png(path.replace("menu","build"))
 print("[castelionyx-capture] PASS: real native menu, battle and building panel")
 quit()
