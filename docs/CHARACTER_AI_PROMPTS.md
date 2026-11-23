# Making an original Kayn-style hero with AI (prompts + pipeline)

Goal: an ORIGINAL character (not a copy of Riot's design) that fits the game's Kayn slot. Keeps the repo license-clean.
Check each tool's terms: you need the right to use and redistribute the output (paid tiers usually grant commercial rights; free tiers often make results public / CC-BY).

## Pipeline
1. **Concept image** (any image generator: Flux, Midjourney, Gemini, ChatGPT images) using prompt A.
2. **Image -> 3D** (Meshy, Tripo, Rodin/Hyper3D, Hunyuan3D, Trellis). Upload the front image; ask for PBR textures, ~30-60k triangles, quad/clean topology if offered.
3. **Rig**: auto-rig in the same tool or Mixamo (upload the .fbx/.glb, place markers, download with skin). Use **A-pose** if the tool allows (T-pose stretches shoulders); T-pose is fine for Mixamo.
4. **Weapon separately** (prompt B), so it can attach to the hand bone and swing independently.
5. **Animations**: Mixamo (idle, run, sprint, jump, dodge roll, sword/scythe slashes, hit reaction, death) exported as .glb/.fbx "without skin" or with.
6. Drop files into `assets/characters/kayn/` and tell Claude; it wires the model, AnimationTree and weapon socket, then records source + license in `docs/ASSET_REGISTER.md`.

## Prompt A - character concept (front view)
```
Full-body character model sheet, front view, perfectly symmetrical A-pose (arms angled 45 degrees away from the body,
legs slightly apart, hands open), standing straight, plain light-grey background, flat even studio lighting, no shadows,
no text, no logo, sharp focus, 3D game character reference, high detail PBR materials.

Original dark-fantasy scythe assassin, tall lean athletic man in his late twenties, spiky silver-white hair swept back,
pale skin, sharp face with glowing crimson eyes, lower half of the face covered by a black cloth mask, fitted layered
black-and-deep-crimson coat with a high collar, asymmetric shoulder armor on the left shoulder, leather straps and belts,
dark fitted trousers, tall buckled boots, fingerless gloves, a long tattered cape attached at the shoulders.
His right forearm is corrupted by living shadow: dark violet smoke-like tendrils and faint glowing purple veins.
Hands EMPTY (no weapon). Stylized realistic proportions, 7.5 heads tall, game-ready clean silhouette.
```
Negative prompt (if supported): `weapon in hands, text, watermark, logo, background scenery, multiple characters, extra limbs, cropped, cartoon chibi`.

Also generate a **side view** and **back view** with the same prompt (replace "front view"), many image-to-3D tools accept multi-view input and give better results.

## Prompt B - scythe
```
Single large two-handed fantasy scythe, isolated on plain grey background, side view, straight and horizontal,
length about 1.9 meters, long dark wooden shaft wrapped with worn leather grip and red cloth, curved
black-steel blade with glowing crimson runes along the edge, ornate spiked collar where blade meets the shaft,
game asset, PBR materials, no hands, no text.
```

## Prompt C - Shadow Assassin / Rhaast variants (later, same body)
- Shadow Assassin: same prompt, add "blue-violet shadow cloak, lighter slimmer armor, ethereal blue smoke around the shoulders".
- Rhaast: same prompt, add "massive crimson Darkin armor plates, taller and broader, horns of black bone, red glowing core in the chest".

## Technical requirements to ask for / check
- Facing -Z in Godot; origin at the feet; 1 unit = 1 meter; height about 1.85 m.
- Humanoid skeleton (Mixamo naming works), 30-60k triangles, 2K PBR textures, single material or a few.
- Export glTF 2.0 (.glb). Keep cape as part of the mesh or as a separate mesh for later cloth sim.
