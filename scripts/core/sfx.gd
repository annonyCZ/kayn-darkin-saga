class_name Sfx
extends RefCounted
## Procedurally synthesized sound effects and ambience (no audio files needed).
## Replace with recorded assets later; keep the play(name) API.

const RATE := 22050
static var _cache: Dictionary = {}

static func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root

static func get_stream(sfx_name: String) -> AudioStreamWAV:
	if not _cache.has(sfx_name):
		_cache[sfx_name] = _make(sfx_name)
	return _cache[sfx_name]

## Fire-and-forget positional sound. pos == null -> non-positional.
static func play(sfx_name: String, pos: Variant = null, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	var stream := get_stream(sfx_name)
	var player: Node
	if pos is Vector3:
		var p3 := AudioStreamPlayer3D.new()
		p3.stream = stream
		p3.volume_db = volume_db
		p3.pitch_scale = pitch * randf_range(0.95, 1.05)
		p3.unit_size = 14.0
		p3.max_distance = 90.0
		player = p3
	else:
		var p2 := AudioStreamPlayer.new()
		p2.stream = stream
		p2.volume_db = volume_db
		p2.pitch_scale = pitch
		player = p2
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child.call_deferred(player)
	if pos is Vector3:
		player.set_deferred("global_position", pos)
	player.call_deferred("play")
	player.connect("finished", player.queue_free)

static func start_ambience() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root.get_node_or_null("AmbienceLoop") != null:
		return
	var holder := Node.new()
	holder.name = "AmbienceLoop"
	for pair: Array in [["wind", -16.0], ["drone", -22.0]]:
		var p := AudioStreamPlayer.new()
		p.stream = get_stream(pair[0])
		p.volume_db = pair[1]
		p.autoplay = true
		holder.add_child(p)
	tree.root.add_child.call_deferred(holder)

# ------------------------------------------------------------------ synthesis
static func _wav(samples: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w

static func _make(n: String) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(n)
	var out := PackedFloat32Array()
	match n:
		"swing", "dodge":
			var len := int(RATE * (0.22 if n == "swing" else 0.3))
			var amp := 0.5 if n == "swing" else 0.28
			out.resize(len)
			var y := 0.0
			for i in len:
				var t := float(i) / len
				var a := lerpf(0.04, 0.45, sin(t * PI) * 0.9 + 0.1)
				y += a * (rng.randf_range(-1.0, 1.0) - y)
				out[i] = y * sin(t * PI) * amp * 2.2
		"hit":
			var len := int(RATE * 0.28)
			out.resize(len)
			var y := 0.0
			var ph := 0.0
			for i in len:
				var t := float(i) / RATE
				ph += TAU * lerpf(150.0, 48.0, minf(t * 6.0, 1.0)) / RATE
				y += 0.3 * (rng.randf_range(-1.0, 1.0) - y)
				out[i] = sin(ph) * exp(-t * 16.0) * 0.85 + y * exp(-t * 30.0) * 0.7
		"parry":
			var len := int(RATE * 0.8)
			out.resize(len)
			for i in len:
				var t := float(i) / RATE
				var s := 0.0
				var freqs := [1180.0, 1770.0, 2460.0, 3290.0]
				for k in freqs.size():
					s += sin(TAU * float(freqs[k]) * t) * exp(-t * (5.0 + k * 2.5)) / (1.0 + k * 0.6)
				out[i] = s * 0.45 + rng.randf_range(-1.0, 1.0) * exp(-t * 90.0) * 0.5
		"block":
			var len := int(RATE * 0.22)
			out.resize(len)
			var y := 0.0
			for i in len:
				var t := float(i) / RATE
				y += 0.12 * (rng.randf_range(-1.0, 1.0) - y)
				out[i] = (sin(TAU * 95.0 * t) * 0.6 + y * 1.4) * exp(-t * 22.0)
		"slam":
			var len := int(RATE * 0.9)
			out.resize(len)
			var y := 0.0
			var ph := 0.0
			for i in len:
				var t := float(i) / RATE
				ph += TAU * lerpf(70.0, 28.0, minf(t * 2.0, 1.0)) / RATE
				y += 0.05 * (rng.randf_range(-1.0, 1.0) - y)
				out[i] = sin(ph) * exp(-t * 4.0) * 0.9 + y * exp(-t * 6.0) * 2.0
		"growl":
			var len := int(RATE * 0.5)
			out.resize(len)
			var y := 0.0
			var ph := 0.0
			for i in len:
				var t := float(i) / len
				ph += lerpf(70.0, 120.0, t) / RATE
				var saw := fmod(ph, 1.0) * 2.0 - 1.0
				y += 0.12 * (saw - y)
				out[i] = y * sin(t * PI) * 0.55
		"death":
			var len := int(RATE * 0.7)
			out.resize(len)
			var y := 0.0
			var ph := 0.0
			for i in len:
				var t := float(i) / RATE
				ph += TAU * lerpf(220.0, 40.0, minf(t * 1.6, 1.0)) / RATE
				y += 0.1 * (rng.randf_range(-1.0, 1.0) - y)
				out[i] = (sin(ph) * 0.6 + y) * exp(-t * 4.5)
		"wind":
			var len := RATE * 6
			out.resize(len)
			var y := 0.0
			for i in len:
				var t := float(i) / len
				y += 0.015 * (rng.randf_range(-1.0, 1.0) - y)
				var lfo := 0.55 + 0.45 * sin(TAU * t * 2.0) * sin(TAU * t * 3.0 + 1.0)
				out[i] = y * lfo * 7.0
			return _wav(out, true)
		"drone":
			var len := RATE * 8
			out.resize(len)
			var freqs := [55.0, 82.5, 110.0, 131.25]
			for i in len:
				var t := float(i) / RATE
				var s := 0.0
				for k in freqs.size():
					s += sin(TAU * float(freqs[k]) * t + sin(TAU * t / 8.0 * (k + 1)) * 0.6)
				out[i] = s * 0.07 * (0.75 + 0.25 * sin(TAU * t / 8.0))
			return _wav(out, true)
		_:
			out.resize(int(RATE * 0.1))
	return _wav(out)
