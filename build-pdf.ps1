Write-Host "Building PDF..." -ForegroundColor Cyan

$files = 1..11 | ForEach-Object { "Answers/$($_)_answ.md" }

$missing = $files | Where-Object { -not (Test-Path $_) }
if ($missing) {
    Write-Host "Files not found:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host $_ -ForegroundColor Red }
    exit 1
}

Write-Host "Creating Answers.pdf (without page numbers)..." -ForegroundColor Cyan
pandoc $files `
    -o Answers.pdf `
    --pdf-engine=xelatex `
    -V geometry:margin=0.5cm `
    -V mainfont="Cambria" `
    -V mathfont="Cambria Math" `
    -V pagestyle=empty `
    --from markdown+tex_math_single_backslash-yaml_metadata_block

if ($LASTEXITCODE -eq 0) {
    Write-Host "PDF created successfully: Answers.pdf" -ForegroundColor Green
    $file = Get-Item Answers.pdf
    Write-Host "Size: $([math]::Round($file.Length / 1KB, 1)) KB" -ForegroundColor Gray
} else {
    Write-Host "Error creating Answers.pdf" -ForegroundColor Red
}
