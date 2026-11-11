import os
import math
import wave
import struct
import random

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

# 6. Ambience Harbour (10-second seamless loop)
def make_ambience_harbour():
    dur = 10.0
    n = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        # Wave swell envelope period ~3.33s (exact 3 periods in 10s for seamless loop)
        wave_env = (math.sin(2 * math.pi * 0.3 * t) * 0.5 + 0.5) ** 2.0
        # Pink noise approximation
        noise = (random.random() * 2.0 - 1.0) * (0.05 + 0.12 * wave_env)
        # Distant low ocean drone
        drone = math.sin(2 * math.pi * 55 * t) * 0.03
        samples.append(noise + drone)
    write_wav("ambience_harbour.wav", samples)

# 7. Ambience Cabin (10-second seamless loop)
def make_ambience_cabin():
    dur = 10.0
    n = int(dur * SAMPLE_RATE)
    samples = []
    for i in range(n):
        t = i / SAMPLE_RATE
        # Wind swell period ~5.0s (exact 2 periods in 10s for seamless loop)
        wind_env = (math.sin(2 * math.pi * 0.2 * t) * 0.5 + 0.5)
        noise = (random.random() * 2.0 - 1.0) * (0.03 + 0.07 * wind_env)
        drone = math.sin(2 * math.pi * 75 * t) * 0.02
        samples.append(noise + drone)
    write_wav("ambience_cabin.wav", samples)

# 8. Music Menu (16-second seamless cozy loop)
def make_music_menu():
    dur = 16.0
    n = int(dur * SAMPLE_RATE)
    # Chord progression: Cmaj7 (0..4s), Am7 (4..8s), Fmaj7 (8..12s), G6 (12..16s)
    chords = [
        [261.63, 329.63, 392.00, 493.88], # C, E, G, B
        [220.00, 261.63, 329.63, 392.00], # A, C, E, G
        [174.61, 261.63, 329.63, 349.23], # F, C, E, F
        [196.00, 246.94, 293.66, 392.00]  # G, B, D, G
    ]
    samples = [0.0] * n
    for chord_idx, chord in enumerate(chords):
        chord_start = chord_idx * 4.0
        for note_idx, freq in enumerate(chord):
            # Arpeggiated soft warm key strike
            note_time = chord_start + note_idx * 0.5
            start_sample = int(note_time * SAMPLE_RATE)
            note_dur = 3.2
            note_n = int(note_dur * SAMPLE_RATE)
            for j in range(note_n):
                idx = start_sample + j
                if idx < n:
                    t = j / SAMPLE_RATE
                    # Soft chime attack and warm decay
                    attack = min(1.0, t / 0.04)
                    decay = math.exp(-t * 1.5)
                    env = attack * decay
                    val = (math.sin(2 * math.pi * freq * t) +
                           0.35 * math.sin(2 * math.pi * freq * 2.0 * t)) * env * 0.08
                    samples[idx] += val
    # Smooth loop boundary
    fade_len = int(0.2 * SAMPLE_RATE)
    for i in range(fade_len):
        f = i / fade_len
        samples[i] = samples[i] * f + samples[n - fade_len + i] * (1.0 - f)
    write_wav("music_menu.wav", samples)

# 9. Music Building (16-second seamless calm loop)
def make_music_building():
    dur = 16.0
    n = int(dur * SAMPLE_RATE)
    # Pentatonic melody notes: C4, D4, E4, G4, A4, C5
    scale = [261.63, 293.66, 329.63, 392.00, 440.00, 523.25]
    melody = [
        (0.0, scale[2]), (1.0, scale[3]), (2.0, scale[4]), (3.0, scale[5]),
        (4.0, scale[4]), (5.5, scale[3]), (7.0, scale[2]),
        (8.0, scale[1]), (9.0, scale[2]), (10.5, scale[3]),
        (12.0, scale[4]), (14.0, scale[2])
    ]
    samples = [0.0] * n
    # Warm background pad chord (C -> G -> Am -> F)
    for i in range(n):
        t = i / SAMPLE_RATE
        chord_f = 261.63 if t < 4.0 else (196.0 if t < 8.0 else (220.0 if t < 12.0 else 174.61))
        pad = (math.sin(2 * math.pi * chord_f * t) * 0.03 +
               math.sin(2 * math.pi * chord_f * 1.5 * t) * 0.02)
        samples[i] += pad

    for note_time, freq in melody:
        start_sample = int(note_time * SAMPLE_RATE)
        note_dur = 2.5
        note_n = int(note_dur * SAMPLE_RATE)
        for j in range(note_n):
            idx = start_sample + j
            if idx < n:
                t = j / SAMPLE_RATE
                attack = min(1.0, t / 0.05)
                decay = math.exp(-t * 1.8)
                val = math.sin(2 * math.pi * freq * t) * attack * decay * 0.12
                samples[idx] += val
    write_wav("music_building.wav", samples)

if __name__ == "__main__":
    random.seed(42)
    make_click_place()
    make_pickup()
    make_rotate()
    make_reject()
    make_chime()
    make_ambience_harbour()
    make_ambience_cabin()
    make_music_menu()
    make_music_building()
    print("All 9 audio assets generated successfully.")
