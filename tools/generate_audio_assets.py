import os
import math
import wave
import struct
import random
import subprocess
import tempfile

import numpy as np

SAMPLE_RATE = 44100
OUT_DIR = "game/assets/audio"
os.makedirs(OUT_DIR, exist_ok=True)

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

# Original score: a slow, loosely timed duet for felt keys and plucked strings.
# MIDI voicings retain common tones through chord changes.
VOICINGS = {
    "Dadd9": (38, (57, 62, 64, 66)),
    "Bm7": (35, (57, 59, 62, 66)),
    "Gmaj7": (43, (55, 59, 62, 66)),
    "G6": (43, (55, 59, 62, 64)),
    "A6": (45, (57, 61, 64, 66)),
    "A7sus": (45, (55, 57, 62, 64)),
    "Em7": (40, (55, 59, 62, 64)),
    "F#m7": (42, (57, 59, 61, 64)),
    "D/F#": (42, (57, 62, 64, 66)),
}
MENU = (
    "Dadd9", "Bm7", "Gmaj7", "A6", "D/F#", "G6", "Em7", "A7sus",
    "Bm7", "F#m7", "Gmaj7", "Dadd9", "Em7", "G6", "D/F#", "A7sus",
)
BUILDING = (
    "Dadd9", "Gmaj7", "Bm7", "A6", "D/F#", "G6", "Em7", "A7sus",
    "Bm7", "F#m7", "Gmaj7", "Dadd9", "Em7", "G6", "D/F#", "A7sus",
    "Dadd9", "Em7", "Bm7", "G6", "F#m7", "Gmaj7", "Em7", "A7sus",
)
MELODY = (
    (0.75, 69, 0.61), (2.5, 74, 0.53), (4.0, 73, 0.42),
    (5.0, 69, 0.50), (7.75, 66, 0.40), (10.0, 67, 0.55),
    (11.0, 71, 0.48), (13.5, 69, 0.38), (16.75, 69, 0.52),
    (18.5, 76, 0.51), (20.25, 74, 0.42), (21.75, 71, 0.43),
    (24.0, 67, 0.53), (25.75, 66, 0.38), (27.5, 64, 0.36),
    (30.0, 69, 0.37), (33.0, 66, 0.59), (34.5, 69, 0.50),
    (37.0, 73, 0.46), (40.0, 74, 0.52), (42.0, 71, 0.46),
    (44.25, 69, 0.43), (49.0, 67, 0.42), (50.5, 71, 0.48),
    (53.0, 69, 0.46), (55.5, 64, 0.35), (57.0, 66, 0.47),
    (60.25, 64, 0.40), (62.25, 62, 0.32),
)


def render_note(midi, instrument, strength, length, sample_rate):
    """Damped, mildly inharmonic partials model a struck or plucked string."""
    t = np.arange(int(sample_rate * length)) / sample_rate
    frequency = 440.0 * 2 ** ((midi - 69) / 12.0)
    if instrument == "felt":
        partials = (1.0, 0.31, 0.17, 0.058, 0.028, 0.015)
        stiffness, damping, attack = 0.00011, 1.44, 0.010
    else:
        partials = (0.87, 0.39, 0.18, 0.094, 0.061, 0.029)
        stiffness, damping, attack = 0.00003, 2.14, 0.007

    note = np.zeros_like(t)
    for order, partial in enumerate(partials, 1):
        f = frequency * order * math.sqrt(1 + stiffness * order ** 2)
        decay = np.exp(-t * (damping + 0.67 * (order - 1)))
        note += partial * decay * np.sin(math.tau * f * t)
        if instrument == "felt" and order <= 3:
            note += 0.13 * partial * decay * np.sin(math.tau * f * 1.0017 * t)
    envelope = np.minimum(1.0, t / attack) * np.minimum(1.0, (length - t) / 0.15)
    return note * envelope * strength


def write_score(filename, voicings, tempo, melodic):
    """Wrap releases and room reflections into the first bar for a sample-continuous loop."""
    sample_rate = 32000
    seconds_per_beat = 60.0 / tempo
    frame_count = round(len(voicings) * 4 * seconds_per_beat * sample_rate)
    score = np.zeros((frame_count, 2), dtype=np.float64)
    timing = random.Random(9421 if melodic else 643)

    def add_note(beat, midi, instrument, strength, pan, length=3.0):
        humanized_beat = beat + timing.uniform(-0.012, 0.012)
        start = round(humanized_beat * seconds_per_beat * sample_rate)
        strength *= timing.uniform(0.93, 1.06)
        note = render_note(midi, instrument, strength, length, sample_rate)
        stereo = note[:, None] * np.array([math.sqrt((1 - pan) / 2), math.sqrt((1 + pan) / 2)])
        indices = (np.arange(note.size) + start) % frame_count
        score[indices] += stereo

    for bar, chord in enumerate(voicings):
        bass, chord_notes = VOICINGS[chord]
        downbeat = 4 * bar
        add_note(downbeat, bass + 12, "plucked", 0.36, -0.13)
        if bar % 4 != 3:
            add_note(downbeat + 2.5, bass + 19, "plucked", 0.15, -0.19)
        # Leave the third beat open and vary the voicing order across the phrase.
        pattern = ((0.5, 0), (1.0, 2), (1.75, 1), (3.25, 3))
        if bar % 4 == 2:
            pattern = ((0.5, 1), (1.5, 0), (2.75, 3), (3.5, 2))
        for step, chord_index in pattern:
            strength = 0.18 if step == 0.5 else 0.11
            instrument = "felt" if melodic else "plucked"
            add_note(downbeat + step, chord_notes[chord_index], instrument, strength, 0.24)
        if not melodic and bar % 2 == 0:
            add_note(downbeat + 1.75, chord_notes[-1] + 12, "felt", 0.13, -0.29)
            add_note(downbeat + 3.5, chord_notes[1] + 12, "felt", 0.11, -0.29)

    if melodic:
        for beat, midi, strength in MELODY:
            add_note(beat, midi, "felt", strength, -0.26, 3.5)

    dry = score.copy()
    # Short asymmetric stereo reflections with dark crossfeed.
    for delay, wet in ((0.037, 0.13), (0.063, 0.11), (0.102, 0.085), (0.159, 0.06), (0.221, 0.035)):
        score += wet * np.roll(dry[:, ::-1], round(delay * sample_rate), axis=0)
    score -= np.mean(score, axis=0)
    target_peak = 0.42 if melodic else 0.34
    score *= target_peak / np.max(np.abs(score))
    pcm = np.round(np.clip(score, -1.0, 1.0) * 32767).astype("<i2")

    with tempfile.NamedTemporaryFile(suffix=".wav") as source:
        with wave.open(source.name, "wb") as wav:
            wav.setnchannels(2)
            wav.setsampwidth(2)
            wav.setframerate(sample_rate)
            wav.writeframes(pcm.tobytes())
        subprocess.run(
            ["ffmpeg", "-v", "error", "-y", "-i", source.name, "-c:a", "libvorbis", "-q:a", "5",
             os.path.join(OUT_DIR, filename)],
            check=True,
        )
    print(f"Generated {filename}: {frame_count / sample_rate:.2f}s stereo loop")


if __name__ == "__main__":
    random.seed(42)
    make_click_place()
    make_pickup()
    make_rotate()
    make_reject()
    make_chime()
    write_score("music_menu.ogg", MENU, tempo=76, melodic=True)
    write_score("music_building.ogg", BUILDING, tempo=70, melodic=False)
