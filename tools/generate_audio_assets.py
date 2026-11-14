import argparse
import os
import math
import wave
import struct
import random
import subprocess
import tempfile

SAMPLE_RATE = 44100
OUT_DIR = "game/assets/audio"

def write_wav(filename, samples, sample_rate=SAMPLE_RATE, channels=1):
    path = os.path.join(OUT_DIR, filename)
    with wave.open(path, 'w') as wf:
        wf.setnchannels(channels)
        wf.setsampwidth(2) # 16-bit
        wf.setframerate(sample_rate)
        # Convert float samples (-1.0 to 1.0) to 16-bit signed ints
        data = bytearray()
        for s in samples:
            val = max(-32767, min(32767, int(s * 32767)))
            data.extend(struct.pack('<h', val))
        wf.writeframes(data)
    print(f"Generated {filename}: {len(samples)/sample_rate:.2f}s ({len(samples)} samples)")

# 1. Placement Click (crisp plastic snap with warm low tap)
def make_click_place():
    dur = 0.12
    n = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        # Fast attack, dual resonance (2300Hz high snap + 480Hz plastic body)
        env_snap = math.exp(-t * 90.0)
        env_body = math.exp(-t * 40.0)
        s_snap = math.sin(2 * math.pi * 2300 * t) * env_snap
        s_body = math.sin(2 * math.pi * 480 * t) * env_body
        noise = (random.random() * 2.0 - 1.0) * math.exp(-t * 150.0) * 0.3
        val = (s_snap * 0.6 + s_body * 0.4 + noise) * 0.95
        samples.append(val)
    write_wav("click_place.wav", samples)

# 2. Pickup (soft plastic lift / rustle)
def make_pickup():
    dur = 0.08
    n = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 60.0)
        s1 = math.sin(2 * math.pi * 1400 * t) * env
        s2 = math.sin(2 * math.pi * 850 * t) * env
        noise = (random.random() * 2.0 - 1.0) * env * 0.2
        samples.append((s1 * 0.4 + s2 * 0.4 + noise) * 0.7)
    write_wav("pickup.wav", samples)

# 3. Rotate (short dry micro-tick)
def make_rotate():
    dur = 0.04
    n = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 140.0)
        s = math.sin(2 * math.pi * 3200 * t) * env
        samples.append(s * 0.6)
    write_wav("rotate.wav", samples)

# 4. Reject (soft dull error thump)
def make_reject():
    dur = 0.14
    n = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 30.0)
        s = math.sin(2 * math.pi * 160 * (1.0 - t * 3.0) * t) * env
        samples.append(s * 0.8)
    write_wav("reject.wav", samples)

# 5. Chime (restrained pleasant finish chime)
def make_chime():
    dur = 0.6
    n = int(dur * SAMPLE_RATE)
    samples = []
    # E5 (659.25), G#5 (830.61), B5 (987.77)
    freqs = [659.25, 830.61, 987.77]
    for i in range(n):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 7.0)
        s = 0.0
        for fi, f in enumerate(freqs):
            delay = fi * 0.04
            if t > delay:
                dt = t - delay
                s += math.sin(2 * math.pi * f * dt) * math.exp(-dt * 6.0)
        samples.append(s * 0.28)
    write_wav("chime.wav", samples)

# Original LittleBricks score in MIDI note numbers. The major-key opening and
# build cues have different hooks, bass movement and rhythms. The quieter
# workshop cues are written as sustained notes and isolated bell answers.
HARMONY = {
    "D": (38, (62, 66, 69, 74)), "G": (43, (59, 62, 67, 74)),
    "A": (45, (61, 64, 69, 76)), "Bm": (47, (59, 62, 66, 74)),
    "Em": (40, (59, 64, 67, 74)), "F#m": (42, (57, 61, 66, 73)),
    "D/F#": (42, (62, 66, 69, 76)), "Gm": (43, (58, 62, 67, 74)),
    "C": (36, (60, 64, 67, 72)), "F": (41, (60, 65, 69, 72)),
    "Am": (45, (60, 64, 69, 76)), "Dm": (38, (62, 65, 69, 77)),
    "Bb": (46, (58, 62, 65, 74)), "E": (40, (59, 64, 68, 74)),
}

# Each cell is an eighth note. Zero is a rest; -1 sustains the preceding note.
OPENING = (
    ("D", (74, 78, 81, -1, 76, 78, 74, 0)),
    ("A", (73, 76, 81, 85, 81, -1, 78, 76)),
    ("Bm", (78, 81, 83, -1, 86, 85, 81, 78)),
    ("G", (79, -1, 74, 71, 74, -1, 76, 0)),
    ("D/F#", (78, 81, 86, -1, 88, 86, 81, 78)),
    ("Em", (79, 83, 81, 79, 76, -1, 74, 76)),
    ("G", (79, -1, 81, 83, 81, 79, 78, 74)),
    ("A", (76, 73, 76, 81, 85, -1, 81, 0)),
    ("Bm", (86, -1, 83, 81, 78, 81, 74, -1)),
    ("F#m", (73, 78, 81, 85, 81, 76, 73, 0)),
    ("G", (74, -1, 79, 83, 86, -1, 83, 81)),
    ("Gm", (82, 79, 77, 74, 70, -1, 74, 0)),
    ("D", (74, 78, 81, -1, 86, 85, 81, 78)),
    ("G", (79, 83, 86, -1, 83, 81, 79, 0)),
    ("A", (81, 76, 78, 81, 85, 83, 81, 76)),
    ("D", (74, -1, -1, 78, 76, 74, 0, 0)),
)
TABLE = (
    ("G", (67, -1, 71, 74, 0, 76, 74, 71)),
    ("D/F#", (66, 69, 74, -1, 76, 74, 69, 0)),
    ("Em", (67, -1, 71, 76, 79, 76, 74, 71)),
    ("A", (69, 73, 76, -1, 78, 76, 73, 0)),
    ("Bm", (71, 74, 78, 81, 83, -1, 81, 78)),
    ("F#m", (76, 73, 69, -1, 73, 76, 78, 0)),
    ("G", (79, -1, 83, 81, 79, 76, 74, 71)),
    ("D", (74, 78, 81, -1, 78, 76, 74, 0)),
    ("Em", (76, 79, 83, -1, 81, 79, 76, -1)),
    ("G", (74, 79, 83, 86, 83, 81, 79, 0)),
    ("A", (76, 81, 85, -1, 83, 81, 78, 76)),
    ("Bm", (78, -1, 74, 71, 0, 74, 78, 81)),
    ("G", (79, 83, 86, 83, 81, -1, 79, 76)),
    ("A", (78, 76, 73, 69, 73, -1, 76, 81)),
    ("D", (78, 74, 69, 66, 69, 74, 76, 78)),
    ("D", (74, -1, -1, -1, 0, 0, 0, 0)),
)
BRICK_BOX = (
    ("C", (72, 0, 76, 79, 81, 79, 76, 0)),
    ("F", (77, 0, 81, 84, 83, 81, 77, 0)),
    ("Am", (76, 79, 81, 84, 88, -1, 84, 81)),
    ("E", (80, 76, 74, 71, 76, -1, 74, 0)),
    ("Dm", (74, 77, 81, -1, 86, 84, 81, 77)),
    ("Bb", (77, 82, 86, -1, 84, 82, 77, 0)),
    ("F", (81, 84, 89, 88, 84, 81, 77, 81)),
    ("C", (79, -1, 76, 72, 76, -1, 79, 0)),
    ("Am", (81, -1, -1, 84, 83, 81, 79, 76)),
    ("F", (77, -1, 81, 84, 88, -1, 84, 81)),
    ("Bb", (82, 86, 89, -1, 86, 84, 82, 77)),
    ("C", (79, 76, 74, 72, 76, 79, 84, 0)),
    ("Dm", (86, -1, 81, 77, 79, 81, 84, 86)),
    ("F", (84, -1, 81, 77, 81, 84, 89, -1)),
    ("C", (88, 84, 79, 76, 79, 84, 83, 79)),
    ("C", (84, -1, -1, -1, 0, 0, 0, 0)),
)
TINKER = (
    ("F", (65, 69, 72, -1, 69, 72, 77, -1)),
    ("Dm", (74, 72, 69, 65, 69, -1, 72, 74)),
    ("Bb", (77, -1, 74, 70, 72, 74, 77, 79)),
    ("C", (76, 72, 67, -1, 72, 74, 76, 0)),
    ("Am", (76, 81, 84, -1, 83, 79, 76, 72)),
    ("Dm", (74, 77, 81, 84, 86, -1, 84, 81)),
    ("Bb", (82, 77, 74, -1, 77, 79, 82, 84)),
    ("F", (81, 77, 72, -1, 69, 72, 77, 0)),
    ("Gm", (79, -1, 74, 70, 74, 77, 79, 82)),
    ("Bb", (86, -1, -1, 82, 77, 74, 77, 79)),
    ("F", (81, 84, 89, -1, 86, 84, 81, 77)),
    ("Am", (76, 79, 81, 84, 88, -1, 84, 0)),
    ("Dm", (86, -1, 84, 81, 77, 81, 84, 86)),
    ("Bb", (82, 77, 74, 70, 74, 77, 82, 84)),
    ("C", (79, -1, 76, 72, 76, 79, 84, 0)),
    ("F", (77, -1, -1, -1, 0, 0, 0, 0)),
)
RAIN = (
    ("Bm", (78, -1, -1, 74, 0, 0, 81, -1)), ("G", (79, -1, 76, -1, 0, 0, 0, 0)),
    ("D/F#", (76, -1, 74, -1, 0, 69, -1, -1)), ("Em", (71, -1, -1, -1, 0, 0, 0, 0)),
    ("Bm", (74, -1, 78, -1, 0, 0, 83, -1)), ("G", (81, -1, -1, 79, 0, 0, 0, 0)),
    ("Em", (76, -1, 74, -1, 0, 0, 71, -1)), ("A", (73, -1, -1, -1, 0, 0, 0, 0)),
    ("G", (74, -1, -1, 79, 0, 0, 83, -1)), ("D", (81, -1, 78, -1, 0, 0, 0, 0)),
    ("Bm", (74, -1, 76, -1, 78, -1, 81, -1)), ("F#m", (76, -1, -1, -1, 0, 0, 0, 0)),
    ("G", (79, -1, -1, 76, 0, 0, 74, -1)), ("Em", (71, -1, 74, -1, 0, 0, 0, 0)),
    ("A", (76, -1, 73, -1, 0, 0, 69, -1)), ("Bm", (71, -1, -1, -1, 0, 0, 0, 0)),
)
NIGHT = (
    ("D", (81, -1, -1, -1, 86, -1, 88, -1)), ("A", (85, -1, -1, -1, 0, 0, 0, 0)),
    ("Bm", (86, -1, 83, -1, 81, -1, -1, -1)), ("G", (79, -1, -1, -1, 0, 0, 0, 0)),
    ("D/F#", (81, -1, -1, -1, 78, -1, 76, -1)), ("Em", (79, -1, -1, -1, 0, 0, 0, 0)),
    ("Gm", (82, -1, 81, -1, 79, -1, 74, -1)), ("D", (74, -1, -1, -1, 0, 0, 0, 0)),
    ("Bm", (78, -1, -1, -1, 81, -1, 86, -1)), ("G", (83, -1, -1, -1, 0, 0, 0, 0)),
    ("D", (81, -1, 86, -1, 88, -1, 90, -1)), ("A", (88, -1, -1, -1, 0, 0, 0, 0)),
    ("Em", (86, -1, -1, -1, 83, -1, 79, -1)), ("G", (81, -1, -1, -1, 0, 0, 0, 0)),
    ("A", (76, -1, 73, -1, 76, -1, 78, -1)), ("D", (74, -1, -1, -1, 0, 0, 0, 0)),
)


def write_chip_score(filename, chart, tempo, groove, ambient=False, playlist=False):
    import numpy as np

    """Render band-limited pulse, triangle bass and clocked percussion to stereo."""
    rate = 32000
    beat_seconds = 60.0 / tempo
    phrase = chart if not playlist else chart[:8] + chart + chart[8:]
    phrase_length = len(phrase) * 4 * beat_seconds
    frame_count = round((phrase_length + (0.55 if playlist else 0.0)) * rate)
    mix = np.zeros((frame_count, 2), dtype=np.float64)
    noise_rng = np.random.default_rng(626 + tempo)

    def note(start_beat, midi, beats, volume, pan, voice):
        held = beats * beat_seconds
        release = {"pad": 0.57, "bell": 0.64, "lead": 0.048, "answer": 0.036, "bass": 0.048}[voice]
        t = np.arange(round((held + release) * rate)) / rate
        frequency = 440.0 * 2 ** ((midi - 69) / 12.0)
        phase = math.tau * frequency * t
        if voice == "bass":
            tone = np.sin(phase) - np.sin(3 * phase) / 9 + np.sin(5 * phase) / 25
        elif voice == "pad":
            tone = np.sin(phase) * 0.75 + np.sin(phase * 1.004) * 0.20 + np.sin(2 * phase) * 0.12
        elif voice == "bell":
            tone = np.sin(phase) + 0.26 * np.sin(phase * 2.004) * np.exp(-t * 4) + 0.07 * np.sin(phase * 3)
        else:
            duty = 0.26 if voice == "lead" else 0.48
            tone = np.zeros_like(t)
            for n in range(1, min(10, int(5700 / frequency)) + 1):
                amplitude = math.sin(math.pi * n * duty) / (n ** 1.21)
                tone += amplitude * np.cos(n * phase)
        attack = {"pad": 0.32, "bell": 0.024, "lead": 0.008, "answer": 0.005, "bass": 0.008}[voice]
        env = np.minimum(1.0, t / attack) * np.clip((held + release - t) / release, 0.0, 1.0) ** 1.6
        if voice == "bell":
            env *= np.exp(-t * 1.8)
        elif voice in ("lead", "answer"):
            env *= 0.76 + 0.24 * np.exp(-t * 7)
        blend(start_beat, tone * env * volume, pan)

    def blend(start_beat, sound, pan):
        start = round(start_beat * beat_seconds * rate)
        if playlist:
            sound = sound[:max(0, frame_count - start)]
        indices = (np.arange(sound.size) + start) % frame_count
        balance = np.sqrt(np.array([(1 - pan) / 2, (1 + pan) / 2]))
        mix[indices] += sound[:, None] * balance

    def drum(beat, voice, strength):
        t = np.arange(round(0.17 * rate)) / rate
        if voice == "kick":
            phase = math.tau * (47 * t + 3.5 * (1 - np.exp(-28 * t)))
            sound = np.sin(phase) * np.exp(-t * 31)
        else:
            noise = noise_rng.choice((-1.0, 1.0), size=round(t.size / 4) + 1)
            stepped = np.repeat(noise, 4)[:t.size]
            sound = stepped * np.exp(-t * (69 if voice == "hat" else 36))
        blend(beat, sound * np.minimum(1.0, t / 0.003) * strength, 0.22 if voice == "hat" else 0.0)

    for bar, (chord, melody) in enumerate(phrase):
        bar_start = 4 * bar
        bass, harmony = HARMONY[chord]
        for step, midi in enumerate(melody):
            if midi < 1:
                continue
            cells = 1
            while step + cells < len(melody) and melody[step + cells] == -1:
                cells += 1
            note(bar_start + step / 2, midi, cells * 0.5 * (1 if ambient else 0.87), 0.36 if ambient else 0.42, -0.21, "bell" if ambient else "lead")
        if ambient:
            note(bar_start, bass + 12, 3.3, 0.16, -0.09, "pad")
            for chord_note in harmony[:3]:
                note(bar_start + 0.5, chord_note, 3.1, 0.068, 0.25, "pad")
            if bar % 2 == 1:
                note(bar_start + 2.75, harmony[0] + 12, 0.6, 0.12, 0.4, "bell")
            continue

        final_bar = playlist and bar == len(phrase) - 1
        bass_pattern = (
            ((0, 0, 0.67), (1, 7, 0.40), (1.5, 12, 0.38), (2.5, 0, 0.62), (3.5, 7, 0.35)),
            ((0, 0, 0.72), (1.5, 12, 0.44), (2, 7, 0.40), (2.75, 0, 0.44), (3.5, 7, 0.35)),
            ((0, 0, 0.92), (1.5, 7, 0.68), (2.5, 12, 0.42), (3, 0, 0.63)),
        )[groove]
        if final_bar:
            bass_pattern = ((0, 0, 1.65),)
        for offset, interval, duration in bass_pattern:
            note(bar_start + offset, bass + 12 + interval, duration, 0.28, 0.0, "bass")

        counter = ((0.5, 0), (1.25, 2), (2.0, 1), (2.75, 3), (3.5, 2)) if groove == 1 else ((0.75, 1), (1.5, 2), (2.25, 0), (3.25, 3))
        if bar % 4 == 3:
            counter = ((0.5, 1), (1.0, 2), (1.75, 3), (2.5, 2))
        for offset, index in counter:
            if not final_bar or offset < 1:
                note(bar_start + offset, harmony[index], 0.27, 0.19, 0.34, "answer")
        drum(bar_start, "kick", 0.20)
        if not final_bar:
            drum(bar_start + (2.5 if groove == 1 else 2.0), "kick", 0.15)
            drum(bar_start + 1, "snare", 0.075)
            drum(bar_start + 3, "snare", 0.087)
            for step in (0.5, 1.5, 2.5, 3.5):
                drum(bar_start + step, "hat", 0.038 if step % 2 > 1 else 0.025)

    dry = mix.copy()
    for delay, wet in ((0.079, 0.12), (0.163, 0.085), (0.297, 0.055)) if ambient else ((0.071, 0.085), (0.13, 0.046)):
        shift = round(delay * rate)
        reflected = np.roll(dry[:, ::-1], shift, axis=0)
        if playlist:
            reflected[:shift] = 0.0
        mix += wet * reflected
    mix -= np.mean(mix, axis=0)
    mix *= (0.28 if ambient else 0.51) / np.max(np.abs(mix))
    pcm = np.round(np.clip(mix, -1.0, 1.0) * 32767).astype("<i2")

    with tempfile.NamedTemporaryFile(suffix=".wav") as source:
        with wave.open(source.name, "wb") as wav:
            wav.setnchannels(2)
            wav.setsampwidth(2)
            wav.setframerate(rate)
            wav.writeframes(pcm.tobytes())
        subprocess.run(
            ["ffmpeg", "-v", "error", "-y", "-i", source.name, "-c:a", "libvorbis", "-q:a", "5",
             os.path.join(OUT_DIR, filename)],
            check=True,
        )
    print(f"Generated {filename}: {frame_count / rate:.2f}s stereo")


def main():
    parser = argparse.ArgumentParser(description="Regenerate the original LittleBricks brick sounds.")
    parser.add_argument(
        "--legacy-score",
        metavar="DIRECTORY",
        help="Render the retired original score to a separate directory instead of generating sound effects.",
    )
    args = parser.parse_args()
    global OUT_DIR
    if args.legacy_score:
        output = os.path.realpath(args.legacy_score)
        asset_dir = os.path.realpath(OUT_DIR)
        if os.path.commonpath([asset_dir, output]) == asset_dir:
            parser.error("the legacy score must be rendered outside game/assets/audio")
        OUT_DIR = output

    os.makedirs(OUT_DIR, exist_ok=True)
    random.seed(42)
    if args.legacy_score:
        write_chip_score("music_menu.ogg", OPENING, tempo=138, groove=0)
        write_chip_score("music_building.ogg", TABLE, tempo=132, groove=0, playlist=True)
        write_chip_score("music_brick_box.ogg", BRICK_BOX, tempo=146, groove=1, playlist=True)
        write_chip_score("music_tinker.ogg", TINKER, tempo=124, groove=2, playlist=True)
        write_chip_score("music_rain.ogg", RAIN, tempo=79, groove=0, ambient=True)
        write_chip_score("music_night.ogg", NIGHT, tempo=70, groove=0, ambient=True)
        return

    make_click_place()
    make_pickup()
    make_rotate()
    make_reject()
    make_chime()


if __name__ == "__main__":
    main()
