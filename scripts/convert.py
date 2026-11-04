with open("firmware.bin", "rb") as f_in, open("firmware.hex", "w") as f_out:
    while True:
        word = f_in.read(4)
        if not word:
            break
        if len(word) < 4:
            word = word + b'\x00' * (4 - len(word))
        val = int.from_bytes(word, byteorder='little')
        f_out.write(f"{val:08x}\n")