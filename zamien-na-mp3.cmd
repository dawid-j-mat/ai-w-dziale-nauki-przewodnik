@echo off
setlocal
title Zamiana nagrania na mp3
if "%~1"=="" (
  echo.
  echo  Przeciagnij plik z nagraniem na ikone tego programu.
  echo.
  pause
  exit /b
)
set "SKRYPT=%~f0"
:petla
if "%~1"=="" goto koniec
set "NAGRANIE=%~f1"
powershell.exe -NoProfile -Command "$t=[IO.File]::ReadAllText($env:SKRYPT,[Text.Encoding]::UTF8); $z='#--'+'-PS---#'; Invoke-Expression $t.Substring($t.IndexOf($z)+$z.Length)"
shift
goto petla
:koniec
echo.
pause
exit /b

#---PS---#
$ErrorActionPreference = 'Stop'
try {
  $plik = Get-Item -LiteralPath $env:NAGRANIE
  Write-Host ""
  Write-Host ("Zamieniam: " + $plik.Name)
  Write-Host "To może potrwać minutę lub dwie. Nie zamykaj tego okna."
  Add-Type -AssemblyName System.Runtime.WindowsRuntime
  $null = [Windows.Storage.StorageFile, Windows.Storage, ContentType=WindowsRuntime]
  $null = [Windows.Storage.StorageFolder, Windows.Storage, ContentType=WindowsRuntime]
  $null = [Windows.Media.Transcoding.MediaTranscoder, Windows.Media.Transcoding, ContentType=WindowsRuntime]
  $null = [Windows.Media.MediaProperties.MediaEncodingProfile, Windows.Media.MediaProperties, ContentType=WindowsRuntime]
  $metody = [System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 }
  function Czekaj($op, $typ) { $m = ($metody | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0].MakeGenericMethod($typ); $t = $m.Invoke($null, @($op)); $t.Wait(-1) | Out-Null; $t.Result }
  $wej = Czekaj ([Windows.Storage.StorageFile]::GetFileFromPathAsync($plik.FullName)) ([Windows.Storage.StorageFile])
  $folder = Czekaj ([Windows.Storage.StorageFolder]::GetFolderFromPathAsync($plik.DirectoryName)) ([Windows.Storage.StorageFolder])
  $wyj = Czekaj ($folder.CreateFileAsync(($plik.BaseName + ".mp3"), [Windows.Storage.CreationCollisionOption]::GenerateUniqueName)) ([Windows.Storage.StorageFile])
  $format = [Windows.Media.MediaProperties.MediaEncodingProfile]::CreateMp3([Windows.Media.MediaProperties.AudioEncodingQuality]::Medium)
  $prep = Czekaj (([Windows.Media.Transcoding.MediaTranscoder]::new()).PrepareFileTranscodeAsync($wej, $wyj, $format)) ([Windows.Media.Transcoding.PrepareTranscodeResult])
  if ($prep.CanTranscode) {
    $m2 = ($metody | Where-Object { $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncActionWithProgress`1' })[0].MakeGenericMethod([double])
    $t2 = $m2.Invoke($null, @($prep.TranscodeAsync())); $t2.Wait(-1) | Out-Null
    Write-Host ("Gotowe. Nowy plik: " + $wyj.Name)
    Write-Host "Leży w tym samym folderze co nagranie."
  } else {
    Write-Host ("Nie udało się zamienić tego pliku: " + $prep.FailureReason)
  }
} catch {
  Write-Host ("Coś poszło nie tak: " + $_.Exception.Message)
}
