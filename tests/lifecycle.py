#!/usr/bin/env python3
"""Plays a fake GameNight host against Spellstorm, headless.

Checks the session lifecycle and the controller path: the game declares its
settings, prepares a local seat and a bot seat, reports ready, starts, turns a
seat's controller frames into play (the right stick shoots bolts, RB swings
the staff, LT rolls, B then RT is a Flamethrower, LB+X then RT is Chain
Lightning), pauses, resumes and disposes.

    python3 tests/lifecycle.py [--godot path/to/godot] [--pack game.pck]   (needs `websockets`)
"""
import argparse
import asyncio
import json
import os
import subprocess
import sys
from pathlib import Path

import websockets

ROOT = Path(__file__).resolve().parents[1]
PORT = 7941

A, B, X, Y, LB, RB = 0, 1, 2, 3, 4, 5


def frame(buttons=0, rt=False, aim=(0, -32767), lt=False):
    axes = [0, 0, aim[0], aim[1], 32767 if lt else 0, 32767 if rt else 0]
    return {"type": "controller_frame", "controllers": [{"controller": "pad1", "axes": axes, "buttons": buttons}]}


async def run(godot: str, pack: str = "") -> None:
    inbox: asyncio.Queue = asyncio.Queue()
    conn = {}

    async def handler(ws):
        conn["ws"] = ws
        try:
            async for text in ws:
                await inbox.put(json.loads(text))
        except websockets.ConnectionClosed:
            pass

    async def expect(kind, check=lambda m: True, timeout=30.0):
        loop = asyncio.get_running_loop()
        end = loop.time() + timeout
        while True:
            left = end - loop.time()
            if left <= 0:
                raise AssertionError(f"timed out waiting for {kind}")
            m = await asyncio.wait_for(inbox.get(), left)
            if m.get("type") == kind and check(m):
                return m

    async def send(msg):
        await conn["ws"].send(json.dumps(msg))

    async def hold(msg, seconds):
        # The SDK treats input older than 250 ms as released, so keep sending.
        for _ in range(int(seconds / 0.05)):
            await send(msg)
            await asyncio.sleep(0.05)

    lines: list[str] = []

    async def read_stdout(proc):
        loop = asyncio.get_running_loop()
        while True:
            line = await loop.run_in_executor(None, proc.stdout.readline)
            if not line:
                return
            lines.append(line.decode(errors="replace").strip())

    async def saw(text, timeout=8.0):
        loop = asyncio.get_running_loop()
        end = loop.time() + timeout
        while loop.time() < end:
            if any(text in l for l in lines):
                return
            await asyncio.sleep(0.1)
        raise AssertionError(f"game never printed {text!r}; last lines: {lines[-8:]}")

    async with websockets.serve(handler, "127.0.0.1", PORT):
        env = dict(os.environ, GAMENIGHT="1", GAMENIGHT_ADDR=f"127.0.0.1:{PORT}",
                   GAMENIGHT_GAME_ID="spellstorm", GAMENIGHT_TOKEN="t", SPELLSTORM_TRACE="1")
        game = ["--main-pack", pack] if pack else ["--path", str(ROOT)]
        proc = subprocess.Popen([godot, "--headless", *game], env=env,
                                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
        reader = asyncio.create_task(read_stdout(proc))
        try:
            hello = await expect("hello")
            assert hello["game"] == "spellstorm" and hello.get("token") == "t", hello
            await send({"type": "welcome", "party": {}})
            settings = await expect("declare_settings")
            keys = {s["key"] for s in settings["settings"]}
            assert keys == {"friendly_fire", "difficulty"}, keys
            print("ok: settings declared")

            seats = [
                {"index": 0, "controller": "pad1", "occupant": {"kind": "local", "player_id": "joep"}},
                {"index": 1, "occupant": {"kind": "ai"}},
            ]
            players = [{"id": "joep", "name": "Joep", "color": "#3d8fe0"}]
            await send({"type": "prepare", "game": "spellstorm", "session": "s1", "seats": seats, "players": players})
            await expect("ready", lambda m: m.get("session") == "s1")
            await saw("seated Joep (seat 0), bot")
            await send({"type": "start", "session": "s1"})
            print("ok: prepared, ready and started")

            await hold(frame(), 0.3)
            await saw("shoot Joep")
            print("ok: the right stick shoots")
            await hold(frame(1 << RB), 0.1)
            await hold(frame(), 0.4)
            await saw("melee Joep")
            print("ok: RB swings the staff")
            await hold(frame(lt=True), 0.1)
            await hold(frame(), 0.5)
            await saw("dodge Joep")
            print("ok: LT rolls")
            await hold(frame(1 << B), 0.15)
            await hold(frame(), 0.15)
            await hold(frame(0, rt=True), 0.4)
            await hold(frame(), 0.2)
            await saw("cast Joep Flamethrower")
            print("ok: B then RT casts a Flamethrower")

            await hold(frame(1 << LB), 0.15)
            await hold(frame((1 << LB) | (1 << X)), 0.15)
            await hold(frame(), 0.15)
            await hold(frame(0, rt=True), 0.4)
            await hold(frame(), 0.2)
            await saw("cast Joep Chain Lightning")
            print("ok: LB+X then RT casts Chain Lightning")

            await send({"type": "pause", "session": "s1"})
            await saw("paused")
            await send({"type": "resume", "session": "s1"})
            await saw("running")
            print("ok: pause and resume")
            await send({"type": "dispose", "session": "s1"})
            await saw("disposed")
            print("ok: disposed")
        finally:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                proc.kill()
            reader.cancel()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    ap.add_argument("--pack", default="")
    args = ap.parse_args()
    asyncio.run(run(args.godot, args.pack))
    print("lifecycle: all good")
    return 0


if __name__ == "__main__":
    sys.exit(main())
