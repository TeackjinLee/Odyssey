#!/usr/bin/env python3
"""컷신 영상 변환: 받은 원본(assets/source/video/*.mp4) → 게임 영상(assets/video/*.ogv).

    python3 tools/gen_video.py .              # godot 폴더에서, 전부
    python3 tools/gen_video.py . ch1_intro    # 하나만

Godot는 Ogg Theora(.ogv)만 재생하는데, brew의 ffmpeg에는 Theora 인코더가 없다.
그래서 ffmpeg로 프레임(JPG)과 소리(WAV)를 뽑고, 작은 임시 Godot 프로젝트가 프레임을 하나씩 띄우며
무비 메이커(--write-movie, Godot 4.5+)로 .ogv를 쓴다. 창이 잠깐 뜬다(화면 없는 곳에서는 xvfb-run).
"""
import os
import shutil
import subprocess
import sys
import tempfile

FPS = 24
SIZE = (1280, 720)

PROJECT = f"""config_version=5
[application]
run/main_scene="res://main.tscn"
[display]
window/size/viewport_width={SIZE[0]}
window/size/viewport_height={SIZE[1]}
[audio]
driver/mix_rate=48000
"""

SCENE = """[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://main.gd" id="1"]
[node name="Main" type="TextureRect"]
offset_right = %d.0
offset_bottom = %d.0
script = ExtResource("1")
""" % SIZE

# 프레임마다 다음 그림을 띄운다. 소리는 첫 프레임에 틀면 무비 메이커가 같이 담는다.
SCRIPT = """extends TextureRect
var i := 1
var n := %d
func _ready() -> void:
    var p := AudioStreamPlayer.new()
    p.stream = AudioStreamWAV.load_from_file(ProjectSettings.globalize_path("res://audio.raw"))
    add_child(p)
    p.play()
    _show()
func _show() -> void:
    texture = ImageTexture.create_from_image(Image.load_from_file(ProjectSettings.globalize_path("res://frames/%%05d.jpg" %% i)))
func _process(_d: float) -> void:
    i += 1
    if i > n:
        get_tree().quit()
        return
    _show()
"""


def convert(src: str, dst: str) -> None:
    with tempfile.TemporaryDirectory() as tmp:
        frames = os.path.join(tmp, "frames")
        os.makedirs(frames)
        open(os.path.join(frames, ".gdignore"), "w").close()
        ff = ["ffmpeg", "-v", "error", "-y", "-i", src]
        subprocess.run(ff + ["-vf", f"fps={FPS},scale={SIZE[0]}:{SIZE[1]}", "-q:v", "2", os.path.join(frames, "%05d.jpg")], check=True)
        # .wav로 두면 임시 프로젝트가 가져오기를 하려 해서 확장자를 바꾼다
        subprocess.run(ff + ["-vn", "-ac", "2", "-ar", "48000", "-f", "wav", os.path.join(tmp, "audio.raw")], check=True)
        n = len([f for f in os.listdir(frames) if f.endswith(".jpg")])
        for name, text in [("project.godot", PROJECT), ("main.tscn", SCENE), ("main.gd", SCRIPT % n)]:
            with open(os.path.join(tmp, name), "w") as f:
                f.write(text)
        out = os.path.join(tmp, "out.ogv")
        subprocess.run(["godot", "--path", tmp, "--write-movie", out, "--fixed-fps", str(FPS)], check=True,
                stdout=subprocess.DEVNULL)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.move(out, dst)
    print(f"{dst}  ({n} 프레임, {n / FPS:.1f}초, {os.path.getsize(dst) / 1e6:.1f}MB)")


def main(root: str, only: list) -> None:
    src_dir = os.path.join(root, "assets/source/video")
    for f in sorted(os.listdir(src_dir)):
        name, ext = os.path.splitext(f)
        if ext.lower() not in (".mp4", ".mov", ".webm") or (only and name not in only):
            continue
        convert(os.path.join(src_dir, f), os.path.join(root, "assets/video", name + ".ogv"))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else ".", sys.argv[2:])
