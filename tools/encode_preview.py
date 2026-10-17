#!/usr/bin/env python3
"""Cut the takes from tools/capture_preview.sh into the five-second GameNight
preview: 150 frames at 30 FPS, 960x540, silent H.264, and a JPEG poster.

    python3 tools/encode_preview.py TAKES assets/gamenight

CUTS lists each shot: the take, its first frame and what it shows. Every cut
is 30 frames, so five cuts make the 150.
"""
import hashlib, os, subprocess, sys, tempfile, shutil

CUTS = [
    ("chapel", 40, "three wizards cut through skeletons and a necromancer in the chapel graves"),
    ("isles", 40, "storm sprites and bog toads on the bridges of the Sunken Isles"),
    ("pit", 40, "a pack of hellhounds and imps in the Infernal Pit, fire everywhere"),
    ("keep", 40, "four wizards against shieldbearers and a frost brute in the Frozen Keep"),
    ("boss", 70, "the boss of the Catacombs in its arena"),
]
POSTER = ("chapel", 55)
LEN = 30


def main(takes, out):
    os.makedirs(out, exist_ok=True)
    tmp = tempfile.mkdtemp()
    n = 0
    for take, start, _ in CUTS:
        for i in range(LEN):
            src = os.path.join(takes, take, "f%08d.png" % (start + i))
            shutil.copy(src, os.path.join(tmp, "%04d.png" % n))
            n += 1
    mp4 = os.path.join(out, "preview.mp4")
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-framerate", "30", "-i", os.path.join(tmp, "%04d.png"),
        "-vf", "scale=960:540:flags=lanczos,format=yuv420p", "-c:v", "libx264", "-crf", "24", "-preset", "slow",
        "-color_range", "tv", "-movflags", "+faststart", "-an", mp4], check=True)
    take, f = POSTER
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", os.path.join(takes, take, "f%08d.png" % f),
        "-q:v", "3", os.path.join(out, "preview.jpg")], check=True)
    # Decode it all back: frame count, length and how many frames differ.
    probe = subprocess.run(["ffprobe", "-v", "error", "-count_frames", "-select_streams", "v:0", "-show_entries",
        "stream=nb_read_frames,width,height,duration", "-of", "csv=p=0", mp4], capture_output=True, text=True, check=True).stdout.strip()
    hashes = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", mp4, "-f", "framemd5", "-"], capture_output=True, text=True, check=True).stdout
    distinct = len({l.split(",")[-1] for l in hashes.splitlines() if l and not l.startswith("#")})
    print("probe (w,h,duration,frames):", probe, " distinct frames:", distinct)
    for name in ["preview.mp4", "preview.jpg"]:
        p = os.path.join(out, name)
        print(hashlib.sha256(open(p, "rb").read()).hexdigest(), name, os.path.getsize(p))
    shutil.rmtree(tmp)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
