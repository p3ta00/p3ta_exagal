#!/usr/bin/env python3
"""
SecurePass.exe Decryptor
Decrypts SP-prefixed hashes from SecurePass.exe (Vulnlab Wutai/Junon)

Usage:
  securepass_decrypt.py SP81274145f4a5857b839ee7b500f1d66e8a044d12211781b515e7bae67bb7abce
  securepass_decrypt.py -f config.xml
"""
import sys
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

KEY = bytes.fromhex("8623050922AB890BBD2F79886CD6809F")
XOR_KEY = 0x42

def decrypt(sp_hash):
    hex_data = sp_hash.replace("SP", "", 1) if sp_hash.startswith("SP") else sp_hash
    half1 = bytes.fromhex(hex_data[:32])
    half2 = bytes.fromhex(hex_data[32:])

    for iv, ct in [(half1, half2), (half2, half1)]:
        try:
            cipher = AES.new(KEY, AES.MODE_CBC, iv)
            decrypted = unpad(cipher.decrypt(ct), AES.block_size)
            reversed_bytes = decrypted[::-1]
            plaintext = bytes([b ^ XOR_KEY for b in reversed_bytes])
            if all(32 <= b < 127 for b in plaintext):
                return plaintext.decode('ascii')
        except Exception:
            continue
    return None

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <SP_hash>")
        print(f"       {sys.argv[0]} -f <config.xml>")
        sys.exit(1)

    if sys.argv[1] == '-f':
        import re
        with open(sys.argv[2]) as f:
            data = f.read()
        for m in re.finditer(r'<username>([^<]+)</username>\s*<password>(SP[0-9a-fA-F]+)</password>', data):
            user, sp = m.group(1), m.group(2)
            print(f"{user}:{decrypt(sp) or 'FAILED'}")
        for m in re.finditer(r'<password>(SP[0-9a-fA-F]+)</password>', data):
            sp = m.group(1)
            result = decrypt(sp)
            if result:
                print(f"{sp[:20]}... = {result}")
    else:
        for arg in sys.argv[1:]:
            result = decrypt(arg)
            print(f"{result}" if result else f"FAILED: {arg}")
