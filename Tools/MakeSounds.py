r"""Generates the default sound scheme (src/Sound/Default/*.wav).

The sounds are synthesized here from sine tones, so they are part of Paxon and fall under its
license (MIT). Run it from any directory:

    python Tools/MakeSounds.py

Format: PCM, 22050 Hz, 16 bit, mono. The file names are referenced by src/Sound/Default Wave.pxs
and by the installer, so they must not change.
"""
import math
import os
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'src', 'Sound', 'Default')


def note(name):
    """Frequency of a note such as 'C5' or 'F#4' (A4 = 440 Hz)."""
    steps = {'C': -9, 'D': -7, 'E': -5, 'F': -4, 'G': -2, 'A': 0, 'B': 2}
    n = steps[name[0]]
    rest = name[1:]
    if rest.startswith('#'):
        n += 1
        rest = rest[1:]
    return 440.0 * 2 ** ((n + 12 * (int(rest) - 4)) / 12.0)


def tone(freq, length, volume=0.5, decay=6.0, attack=0.004, harmonics=((1, 1.0), (2, 0.25), (3, 0.08))):
    """A bell-like tone: sine with a few harmonics, short attack, exponential decay."""
    n = int(RATE * length)
    out = []
    for i in range(n):
        t = i / float(RATE)
        env = min(1.0, t / attack) * math.exp(-decay * t)
        # fade out over the last 5 ms so the sound never ends with a click
        env *= min(1.0, (n - i) / (RATE * 0.005))
        s = sum(a * math.sin(2 * math.pi * freq * k * t) for k, a in harmonics)
        out.append(volume * env * s)
    return out


def silence(length):
    return [0.0] * int(RATE * length)


def mix(*parts):
    """Sequence of (start in seconds, samples) mixed into one signal."""
    end = max(int(RATE * start) + len(s) for start, s in parts)
    out = [0.0] * end
    for start, s in parts:
        o = int(RATE * start)
        for i, v in enumerate(s):
            out[o + i] += v
    return out


def arpeggio(notes, step, length, **kw):
    return mix(*[(i * step, tone(note(n), length, **kw)) for i, n in enumerate(notes)])


def save(name, samples):
    peak = max(1e-9, max(abs(v) for v in samples))
    scale = min(1.0, 0.9 / peak) * 32767
    path = os.path.join(OUT, name)
    w = wave.open(path, 'wb')
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(RATE)
    w.writeframes(b''.join(struct.pack('<h', int(round(v * scale))) for v in samples))
    w.close()
    print('%-45s %5.2f s' % (name, len(samples) / float(RATE)))


SOUNDS = {
    # rising fifth: own station connects
    'Paxon Connected (outgoing).wav': lambda: arpeggio(['C5', 'G5'], 0.11, 0.45, decay=7),
    # rising triad: another station connects to us
    'Paxon Connected (incoming).wav': lambda: arpeggio(['G4', 'C5', 'E5'], 0.10, 0.5, decay=7),
    # falling fifth: disconnected
    'Paxon Disconnected.wav': lambda: arpeggio(['G5', 'C5'], 0.13, 0.5, decay=6),
    # two short double rings, like a telephone
    'Paxon Ring.wav': lambda: mix(*[(start + k * 0.06, tone(f, 0.12, volume=0.4, decay=18))
                                    for start in (0.0, 0.45)
                                    for k, f in enumerate([1320, 1180, 1320, 1180])]),
    # short soft blip: line received on the active channel
    'Paxon Line Received (active).wav': lambda: tone(note('E6'), 0.07, volume=0.35, decay=45,
                                                      harmonics=((1, 1.0),)),
    # lower, quieter blip: line received on another channel
    'Paxon Line Received (inactive).wav': lambda: tone(note('A5'), 0.08, volume=0.2, decay=40,
                                                        harmonics=((1, 1.0),)),
    # rising arpeggio up to the octave: file transfer finished
    'Paxon File Transfer Complete.wav': lambda: arpeggio(['C5', 'E5', 'G5', 'C6'], 0.09, 0.6, decay=6),
    # two high pings: valid PGP signature
    'Paxon PGP Signature Valid.wav': lambda: mix((0.0, tone(note('B5'), 0.25, decay=14)),
                                                      (0.12, tone(note('E6'), 0.35, decay=10))),
    # very short tick: channel switched
    'Paxon Channel Switch.wav': lambda: tone(2400, 0.025, volume=0.3, decay=120, attack=0.001,
                                           harmonics=((1, 1.0),)),
}

if __name__ == '__main__':
    for name, make in SOUNDS.items():
        save(name, make())
