import math
import struct
import wave

def generate_tone(filename, duration, start_freq, end_freq, waveform='sine', volume=0.5):
    sample_rate = 44100
    num_samples = int(duration * sample_rate)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        for i in range(num_samples):
            t = float(i) / sample_rate
            # Linear frequency sweep
            freq = start_freq + (end_freq - start_freq) * (float(i) / num_samples)
            
            if waveform == 'sine':
                value = math.sin(2.0 * math.pi * freq * t)
            elif waveform == 'square':
                value = 1.0 if math.sin(2.0 * math.pi * freq * t) > 0 else -1.0
            elif waveform == 'sawtooth':
                value = 2.0 * (freq * t - math.floor(freq * t + 0.5))
            else:
                value = 0.0
                
            # Envelope (quick attack, linear decay)
            envelope = 1.0 - (float(i) / num_samples)
            
            sample = int(value * envelope * volume * 32767.0)
            
            # Clamp sample to short range
            sample = max(-32768, min(32767, sample))
            wav_file.writeframes(struct.pack('h', sample))

# 1. Click sound: Short, high pitched, quick decay
generate_tone('click.wav', 0.1, 800, 1200, waveform='square', volume=0.3)

# 2. Drop sound: Thud, low pitched, quick decay
generate_tone('drop.wav', 0.15, 300, 100, waveform='sine', volume=0.6)

# 3. Clear sound: Chime, rising pitch, longer decay
generate_tone('clear.wav', 0.4, 400, 800, waveform='square', volume=0.4)

# 4. Game Over sound: Descending pitch, longer duration
generate_tone('game_over.wav', 1.0, 400, 50, waveform='sawtooth', volume=0.5)

print("Generated click.wav, drop.wav, clear.wav, game_over.wav")
