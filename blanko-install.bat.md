test URL `https://get.microsoft.com/installer/download/9NKSQGP7F2NH?cid=website_cta_psi`

<script type="text/plain" id="cmd-01">

@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "URL=https://example.com/your-installer.exe"

>nul 2>&1 net session || (powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -Verb RunAs -FilePath '%~f0' -ArgumentList '%*'"; exit /b)

set "TLS=([Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12)"
set "WORK=%TEMP%\deploy_%RANDOM%%RANDOM%"
mkdir "%WORK%" >nul 2>&1

for /f "usebackq delims=" %%E in (`powershell -NoProfile -Command "$u='%URL%'; $p=([uri]$u).AbsolutePath; [IO.Path]::GetExtension($p).ToLower()"`) do set "EXT=%%E"
if not defined EXT set "EXT=.bin"
if "%EXT%"=="" set "EXT=.bin"
set "PKG=%WORK%\package%EXT%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; %TLS%; Invoke-WebRequest -Uri '%URL%' -OutFile '%PKG%' -UseBasicParsing" >nul 2>&1 || exit /b 10

for /f "usebackq delims=" %%X in (`powershell -NoProfile -Command "$p='%PKG%'; try{ $s=[IO.File]::OpenRead($p); $b=new-object byte[] 8; $null=$s.Read($b,0,8); $s.Close(); $h=([BitConverter]::ToString($b)).Replace('-',''); if($h -like '504B0304*'){'.zip'} elseif($h -eq 'D0CF11E0A1B11AE1'){'.msi'} else {''} } catch {''}"`) do set "MAGIC=%%X"
if defined MAGIC (
  if /i not "%EXT%"=="%MAGIC%" (
    set "NEW=%WORK%\package%MAGIC%"
    move /y "%PKG%" "%NEW%" >nul
    set "PKG=%NEW%"
    set "EXT=%MAGIC%"
  )
)

set "INSTALLER="
if /i "%EXT%"==".zip" (
  set "EXTRACT=%WORK%\unzipped"
  rd /s /q "%EXTRACT%" >nul 2>&1
  mkdir "%EXTRACT%" >nul 2>&1
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Expand-Archive -Path '%PKG%' -DestinationPath '%EXTRACT%' -Force" >nul 2>&1
  for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "$d='%EXTRACT%'; $c=Get-ChildItem -Recurse -File $d | Where-Object { $_.Extension -in '.exe','.msi' }; if(!$c){''} else { $pref=@('setup.exe','install.exe'); $hit=foreach($p in $pref){$m=Get-ChildItem -Recurse -File $d -Filter $p; if($m){$m|Select-Object -First 1; break}}; if(!$hit){$hit=$c|Sort-Object Length -Descending|Select-Object -First 1}; if($hit){$hit.FullName} }"`) do set "INSTALLER=%%P"
) else (
  set "INSTALLER=%PKG%"
)

if not exist "%INSTALLER%" (rd /s /q "%WORK%" >nul 2>&1 & exit /b 20)

for %%A in ("%INSTALLER%") do set "BASE=%%~nA" & set "EXT2=%%~xA"

taskkill /f /t /im "%BASE%.exe" >nul 2>&1

set "UNINST_DONE="
if /i "%EXT2%"==".msi" (
  for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "$msi='%INSTALLER%'; try{ $wi=New-Object -ComObject WindowsInstaller.Installer; $db=$wi.OpenDatabase($msi,0); $v=$db.OpenView(\"SELECT Value FROM Property WHERE Property='ProductCode'\"); $v.Execute(); $r=$v.Fetch(); if($r){$r.StringData(1)} } catch {''}"`) do set "MSI_PCODE=%%G"
  if defined MSI_PCODE (
    msiexec /x "%MSI_PCODE%" /qn /norestart >nul 2>&1
    set "UNINST_DONE=1"
  )
) else (
  for /f "usebackq delims=" %%N in (`powershell -NoProfile -Command "$f='%INSTALLER%'; $v=[Diagnostics.FileVersionInfo]::GetVersionInfo($f); $n=$v.ProductName; if(!$n){$n=$v.FileDescription}; if(!$n){$n=[IO.Path]::GetFileNameWithoutExtension($f)}; $n"`) do set "PRODNAME=%%N"
  for /f "usebackq delims=" %%U in (`powershell -NoProfile -Command "$n=[regex]::Escape('%PRODNAME%'); $paths='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'; $hit=Get-ChildItem $paths -ErrorAction SilentlyContinue | ForEach-Object {Get-ItemProperty \$_ -ErrorAction SilentlyContinue} | Where-Object { $_.DisplayName -and $_.UninstallString -and ($_.DisplayName -match $n -or $_.DisplayName -like '*%BASE%*') } | Select-Object -First 1; if($hit){$hit.UninstallString} else {''}"`) do set "UNINST=%%U"
  if defined UNINST (
    echo %UNINST% | find /i "msiexec" >nul
    if not errorlevel 1 (
      for /f "tokens=1,* delims= " %%X in ("%UNINST%") do set "MSIARGS=%%Y"
      msiexec %MSIARGS% /qn /norestart >nul 2>&1
    ) else (
      cmd /c "%UNINST% /S /silent /verysilent /quiet /qn /norestart" >nul 2>&1
    )
    set "UNINST_DONE=1"
  )
)

set "COMMON_SILENT=/S /silent /verysilent /quiet /qn /norestart /SuppressReboot"

if /i "%EXT2%"==".msi" (
  msiexec /i "%INSTALLER%" /qn /norestart >nul 2>&1
) else (
  for /f "usebackq delims=" %%C in (`powershell -NoProfile -Command "$f='%INSTALLER%'; ([Diagnostics.FileVersionInfo]::GetVersionInfo($f)).CompanyName"`) do set "COMPANY=%%C"
  set "EXTRA="
  echo %COMPANY% | find /i "bitdefender" >nul && set "EXTRA=/bdparams"
  start /wait "" "%INSTALLER%" %EXTRA% %COMMON_SILENT% >nul 2>&1
)

rd /s /q "%WORK%" >nul 2>&1

</script>

<button onclick="navigator.clipboard.writeText(document.getElementById('cmd-01').textContent)">
Final
</button>

---

<script type="text/plain" id="cmd-02">

@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "URL=exe"

>nul 2>&1 net session || (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -Verb RunAs -FilePath '%~f0' -ArgumentList '%*'"
  exit /b
)

set "TLS=([Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12)"
set "WORK=%TEMP%\deploy_%RANDOM%%RANDOM%"
mkdir "%WORK%" >nul 2>&1

for /f "usebackq delims=" %%E in (`powershell -NoProfile -Command "$u='%URL%'; $p=([uri]$u).AbsolutePath; [IO.Path]::GetExtension($p).ToLower()"`) do set "EXT=%%E"
if not defined EXT set "EXT=.bin"
if "%EXT%"=="" set "EXT=.bin"
set "PKG=%WORK%\package%EXT%"

echo [*] Lade %URL% ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "%TLS%; Invoke-WebRequest -Uri '%URL%' -OutFile '%PKG%' -UseBasicParsing" || (
  echo [!] Download fehlgeschlagen
  exit /b 10
)

for /f "usebackq delims=" %%X in (`powershell -NoProfile -Command "$p='%PKG%'; try{ $s=[IO.File]::OpenRead($p); $b=new-object byte[] 8; $null=$s.Read($b,0,8); $s.Close(); $h=([BitConverter]::ToString($b)).Replace('-',''); if($h -like '504B0304*'){'.zip'} elseif($h -eq 'D0CF11E0A1B11AE1'){'.msi'} else {''} } catch {''}"`) do set "MAGIC=%%X"
if defined MAGIC (
  if /i not "%EXT%"=="%MAGIC%" (
    set "NEW=%WORK%\package%MAGIC%"
    move /y "%PKG%" "%NEW%" >nul
    set "PKG=%NEW%"
    set "EXT=%MAGIC%"
  )
)

set "INSTALLER="
if /i "%EXT%"==".zip" (
  set "EXTRACT=%WORK%\unzipped"
  rd /s /q "%EXTRACT%" >nul 2>&1
  mkdir "%EXTRACT%" >nul 2>&1
  echo [*] Entpacke Archiv ...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%PKG%' -DestinationPath '%EXTRACT%' -Force"
  for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "$d='%EXTRACT%'; $c=Get-ChildItem -Recurse -File $d | Where-Object { $_.Extension -in '.exe','.msi' }; if(!$c){''} else { $pref=@('setup.exe','install.exe'); $hit=foreach($p in $pref){$m=Get-ChildItem -Recurse -File $d -Filter $p; if($m){$m|Select-Object -First 1; break}}; if(!$hit){$hit=$c|Sort-Object Length -Descending|Select-Object -First 1}; if($hit){$hit.FullName} }"`) do set "INSTALLER=%%P"
) else (
  set "INSTALLER=%PKG%"
)

if not exist "%INSTALLER%" (
  echo [!] Keine installierbare Datei gefunden.
  rd /s /q "%WORK%" >nul 2>&1
  exit /b 20
)

for %%A in ("%INSTALLER%") do set "BASE=%%~nA" & set "EXT2=%%~xA"
echo [*] Gefundener Installer: %INSTALLER%

echo [*] Beende laufende Prozesse ...
taskkill /f /t /im "%BASE%.exe" >nul 2>&1

set "UNINST_DONE="
if /i "%EXT2%"==".msi" (
  for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "$msi='%INSTALLER%'; try{ $wi=New-Object -ComObject WindowsInstaller.Installer; $db=$wi.OpenDatabase($msi,0); $v=$db.OpenView(\"SELECT Value FROM Property WHERE Property='ProductCode'\"); $v.Execute(); $r=$v.Fetch(); if($r){$r.StringData(1)} } catch {''}"`) do set "MSI_PCODE=%%G"
  if defined MSI_PCODE (
    echo [*] Versuche Deinstallation (MSI %MSI_PCODE%) ...
    msiexec /x "%MSI_PCODE%" /qn /norestart >nul 2>&1
    set "UNINST_DONE=1"
  )
) else (
  for /f "usebackq delims=" %%N in (`powershell -NoProfile -Command "$f='%INSTALLER%'; $v=[Diagnostics.FileVersionInfo]::GetVersionInfo($f); $n=$v.ProductName; if(!$n){$n=$v.FileDescription}; if(!$n){$n=[IO.Path]::GetFileNameWithoutExtension($f)}; $n"`) do set "PRODNAME=%%N"
  for /f "usebackq delims=" %%U in (`powershell -NoProfile -Command "$n=[regex]::Escape('%PRODNAME%'); $paths='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'; $hit=Get-ChildItem $paths -ErrorAction SilentlyContinue | ForEach-Object {Get-ItemProperty \$_ -ErrorAction SilentlyContinue} | Where-Object { $_.DisplayName -and $_.UninstallString -and ($_.DisplayName -match $n -or $_.DisplayName -like '*%BASE%*') } | Select-Object -First 1; if($hit){$hit.UninstallString} else {''}"`) do set "UNINST=%%U"
  if defined UNINST (
    echo [*] Versuche Deinstallation (EXE) ...
    echo %UNINST% | find /i "msiexec" >nul
    if not errorlevel 1 (
      for /f "tokens=1,* delims= " %%X in ("%UNINST%") do set "MSIARGS=%%Y"
      msiexec %MSIARGS% /qn /norestart >nul 2>&1
    ) else (
      rem CMD
      cmd /c "%UNINST% /S /silent /verysilent /quiet /qn /norestart" >nul 2>&1
    )
    set "UNINST_DONE=1"
  )
)

set "COMMON_SILENT=/S /silent /verysilent /quiet /qn /norestart /SuppressReboot"
echo [*] Installiere ...
if /i "%EXT2%"==".msi" (
  msiexec /i "%INSTALLER%" /qn /norestart
) else (
  for /f "usebackq delims=" %%C in (`powershell -NoProfile -Command "$f='%INSTALLER%'; ([Diagnostics.FileVersionInfo]::GetVersionInfo($f)).CompanyName"`) do set "COMPANY=%%C"
  set "EXTRA="
  echo %COMPANY% | find /i "bitdefender" >nul && set "EXTRA=/bdparams"
  start /wait "" "%INSTALLER%" %EXTRA% %COMMON_SILENT%
)

rd /s /q "%WORK%" >nul 2>&1
echo [√] Fertig.
exit /b 0

</script>

<button onclick="navigator.clipboard.writeText(document.getElementById('cmd-02').textContent)">
v2
</button>

---

<script type="text/plain" id="cmd-03">

@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "URL=https://example.com/your-installer.exe"

>nul 2>&1 net session || (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -Verb RunAs -FilePath '%~f0' -ArgumentList '%*'"
  exit /b
)

set "TLS=([Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12)"
set "WORK=%TEMP%\deploy_%RANDOM%%RANDOM%"
mkdir "%WORK%" >nul 2>&1

for /f "usebackq delims=" %%E in (`powershell -NoProfile -Command "$u='%URL%'; $p=([uri]$u).AbsolutePath; [IO.Path]::GetExtension($p).ToLower()"`) do set "EXT=%%E"
if not defined EXT set "EXT=.bin"
if "%EXT%"=="" set "EXT=.bin"

set "PKG=%WORK%\package%EXT%"

echo [*] Lade %URL% ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "%TLS%; Invoke-WebRequest -Uri '%URL%' -OutFile '%PKG%' -UseBasicParsing" || (
  echo [!] Download fehlgeschlagen
  exit /b 10
)

for /f "usebackq delims=" %%X in (`powershell -NoProfile -Command "$p='%PKG%'; try{ $s=[IO.File]::OpenRead($p); $b=new-object byte[] 8; $null=$s.Read($b,0,8); $s.Close(); $h=([BitConverter]::ToString($b)).Replace('-',''); if($h -like '504B0304*'){'.zip'} elseif($h -eq 'D0CF11E0A1B11AE1'){'.msi'} else {''} } catch {''}"`) do set "MAGIC=%%X"
if defined MAGIC (
  if /i not "%EXT%"=="%MAGIC%" (
    set "NEW=%WORK%\package%MAGIC%"
    move /y "%PKG%" "%NEW%" >nul
    set "PKG=%NEW%"
    set "EXT=%MAGIC%"
  )
)

set "INSTALLER="
if /i "%EXT%"==".zip" (
  set "EXTRACT=%WORK%\unzipped"
  rd /s /q "%EXTRACT%" >nul 2>&1
  mkdir "%EXTRACT%" >nul 2>&1
  echo [*] Entpacke Archiv ...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%PKG%' -DestinationPath '%EXTRACT%' -Force"
  for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command "$d='%EXTRACT%'; $c=Get-ChildItem -Recurse -File $d | Where-Object { $_.Extension -in '.exe','.msi' }; if(!$c){''} else { $pref=@('setup.exe','install.exe'); $hit=foreach($p in $pref){$m=Get-ChildItem -Recurse -File $d -Filter $p; if($m){$m|Select-Object -First 1; break}}; if(!$hit){$hit=$c|Sort-Object Length -Descending|Select-Object -First 1}; if($hit){$hit.FullName} }"`) do set "INSTALLER=%%P"
) else (
  set "INSTALLER=%PKG%"
)

if not exist "%INSTALLER%" (
  echo [!] Keine installierbare Datei gefunden.
  rd /s /q "%WORK%" >nul 2>&1
  exit /b 20
)

for %%A in ("%INSTALLER%") do set "BASE=%%~nA" & set "EXT2=%%~xA"
echo [*] Gefundener Installer: %INSTALLER%

echo [*] Beende laufende Prozesse ...
taskkill /f /t /im "%BASE%.exe" >nul 2>&1

set "UNINST_DONE="
if /i "%EXT2%"==".msi" (
  for /f "usebackq delims=" %%G in (`powershell -NoProfile -Command "$msi='%INSTALLER%'; try{ $wi=New-Object -ComObject WindowsInstaller.Installer; $db=$wi.OpenDatabase($msi,0); $v=$db.OpenView(\"SELECT Value FROM Property WHERE Property='ProductCode'\"); $v.Execute(); $r=$v.Fetch(); if($r){$r.StringData(1)} } catch {''}"`) do set "MSI_PCODE=%%G"
  if defined MSI_PCODE (
    echo [*] Versuche Deinstallation (MSI %MSI_PCODE%) ...
    msiexec /x "%MSI_PCODE%" /qn /norestart >nul 2>&1
    set "UNINST_DONE=1"
  )
) else (
  for /f "usebackq delims=" %%N in (`powershell -NoProfile -Command "$f='%INSTALLER%'; $v=[Diagnostics.FileVersionInfo]::GetVersionInfo($f); $n=$v.ProductName; if(!$n){$n=$v.FileDescription}; if(!$n){$n=[IO.Path]::GetFileNameWithoutExtension($f)}; $n"`) do set "PRODNAME=%%N"
  for /f "usebackq delims=" %%U in (`powershell -NoProfile -Command "$n=[regex]::Escape('%PRODNAME%'); $paths='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'; $hit=Get-ChildItem $paths -ErrorAction SilentlyContinue | ForEach-Object {Get-ItemProperty \$_ -ErrorAction SilentlyContinue} | Where-Object { $_.DisplayName -and $_.UninstallString -and ($_.DisplayName -match $n -or $_.DisplayName -like '*%BASE%*') } | Select-Object -First 1; if($hit){$hit.UninstallString} else {''}"`) do set "UNINST=%%U"
  if defined UNINST (
    echo [*] Versuche Deinstallation (EXE) ...
    rem msiexec
    echo %UNINST% | find /i "msiexec" >nul
    if not errorlevel 1 (
      for /f "tokens=1,* delims= " %%X in ("%UNINST%") do (
        set "MSIARGS=%%Y"
      )
      echo %MSIARGS% | find /i "/x" >nul || set "MSIARGS=/x %MSIARGS%"
      powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'msiexec.exe' -ArgumentList '%MSIARGS% /qn /norestart' -Wait" >nul 2>&1
    ) else (
      powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c','%UNINST% /S /silent /verysilent /quiet /qn /norestart' -WindowStyle Hidden -Wait" >nul 2>&1
    )
    set "UNINST_DONE=1"
  )
)

set "COMMON_SILENT=/S /silent /verysilent /quiet /qn /norestart /SuppressReboot"
echo [*] Installiere ...
if /i "%EXT2%"==".msi" (
  msiexec /i "%INSTALLER%" /qn /norestart
) else (
  rem Bitdefender
  set "EXTRA="
  for /f "usebackq delims=" %%C in (`powershell -NoProfile -Command "$f='%INSTALLER%'; ([Diagnostics.FileVersionInfo]::GetVersionInfo($f)).CompanyName"`) do set "COMPANY=%%C"
  echo %COMPANY% | find /i "bitdefender" >nul && set "EXTRA=/bdparams"
  start /wait "" "%INSTALLER%" %EXTRA% %COMMON_SILENT%
)

rd /s /q "%WORK%" >nul 2>&1
echo [√] Fertig.
exit /b 0

</script>

<button onclick="navigator.clipboard.writeText(document.getElementById('cmd-03').textContent)">
v1
</button>
