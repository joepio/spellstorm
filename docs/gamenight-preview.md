# GameNight store media

[preview.mp4](../assets/gamenight/preview.mp4) is the five-second gameplay clip
for the store: 150 frames, 960x540, 30 FPS, silent H.264. Poster
[preview.jpg](../assets/gamenight/preview.jpg), portrait
[cover.png](../assets/gamenight/cover.png), square
[icon.png](../assets/gamenight/icon.png) and the TV screenshot
[gameplay.png](../assets/gamenight/gameplay.png) sit next to it.

It is real gameplay from commit d1e0d38: bots play with the normal simulation,
spells and renderer. The staging is honest but deliberate: `--at` starts the
wizards part of the way along a level (`-1` at the boss's arena), `--spawn`
puts a set of monsters round them, and `--zoom 0.62` brings the camera closer
than in play so it reads on a phone. Nothing is sped up or faked.

Recreate it:

    GODOT=godot tools/capture_preview.sh /tmp/takes
    python3 tools/encode_preview.py /tmp/takes assets/gamenight

| Cut | Take, frames | Shows |
| --- | --- | --- |
| 1 | chapel 56-85 | three wizards against skeletons and a necromancer in the graves: lightning, a staff swing |
| 2 | isles 20-49 | storm sprites and bog toads on a bridge over the water, a fire nova |
| 3 | pit 22-51 | hellhounds, imps and a demon in the Infernal Pit, a void burst |
| 4 | keep 48-77 | four wizards, shieldbearers and a frost brute in the Frozen Keep |
| 5 | boss 99-128 | four wizards burn down the Bloated Abbot in its arena |

Seeds and player counts per take are in tools/capture_preview.sh.

    92784a5b530cf004c46b16ef0907a08f879dc7f89a1ab3cff4210cf8d30b69d3  preview.mp4
    a5a1d13d4e978a47c0f09ec9d8e54ab663572c8e345e6b90d13653f9f2c6abd9  preview.jpg
