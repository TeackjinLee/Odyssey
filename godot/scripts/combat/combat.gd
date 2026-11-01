class_name Combat
## 근접 판정과 화살 발사. 판정은 화면 좌표의 부채꼴로 한다(위아래는 조금 짧게 쳐서 쿼터뷰에 맞춤).

const Y_STRETCH := 1.25


static func ground_dist(a: Vector2, b: Vector2) -> float:
	var d := b - a
	return Vector2(d.x, d.y * Y_STRETCH).length()


static func melee(attacker: Actor, reach: float, arc_deg: float, dmg: float, kb: float, heavy := false) -> Array:
	var hits: Array = []
	for a in attacker.get_tree().get_nodes_in_group("actors"):
		if a == attacker or a.team == attacker.team or not a.is_alive():
			continue
		var to: Vector2 = a.global_position - attacker.global_position
		var d := ground_dist(attacker.global_position, a.global_position)
		if d > reach + 5.0:
			continue
		if d > 9.0 and absf(rad_to_deg(attacker.facing.angle_to(to))) > arc_deg * 0.5:
			continue
		var r: String = a.take_hit(dmg * attacker.damage_mult, attacker, kb, heavy)
		if r != "miss":
			hits.append(a)
			if r == "killed" and a.team == Actor.Team.TROJAN:
				Game.stats["kills"] += 1
	return hits


static func area(attacker: Actor, center: Vector2, radius: float, dmg: float, kb: float, heavy := true) -> Array:
	var hits: Array = []
	for a in attacker.get_tree().get_nodes_in_group("actors"):
		if a == attacker or a.team == attacker.team or not a.is_alive():
			continue
		if ground_dist(center, a.global_position) <= radius:
			var r: String = a.take_hit(dmg * attacker.damage_mult, attacker, kb, heavy)
			if r != "miss":
				hits.append(a)
	return hits


static func shoot(shooter: Actor, target_pos: Vector2, dmg: float, speed := 300.0) -> void:
	var p := Projectile.new()
	p.shooter = shooter
	p.team = shooter.team
	p.damage = dmg * shooter.damage_mult
	var dir := (target_pos - shooter.global_position).normalized()
	p.velocity = dir * speed
	p.position = shooter.global_position + dir * 8.0
	Game.level.fx_layer.add_child(p)
	Sfx.play("bow")
