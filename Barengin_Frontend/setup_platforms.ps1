$ErrorActionPreference = 'Stop'

Write-Host "Menyiapkan platform Android dan Web untuk Barengin..." -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw "Flutter belum ditemukan di PATH. Buka terminal baru setelah memasang Flutter, lalu jalankan kembali script ini."
}

$projectRoot = $PSScriptRoot
$seed = Join-Path $env:TEMP ("barengin_platform_seed_" + [Guid]::NewGuid().ToString('N'))

try {
    flutter create --platforms=android,web --project-name barengin_app --org id.barengin $seed
    if ($LASTEXITCODE -ne 0) { throw "flutter create gagal dengan exit code $LASTEXITCODE" }

    foreach ($platform in @('android', 'web')) {
        $source = Join-Path $seed $platform
        $destination = Join-Path $projectRoot $platform
        if (Test-Path $destination) { Remove-Item $destination -Recurse -Force }
        Copy-Item $source $destination -Recurse -Force
    }

    $manifest = Join-Path $projectRoot 'android/app/src/main/AndroidManifest.xml'
    if (Test-Path $manifest) {
        $xml = Get-Content $manifest -Raw
        $permissions = @(
            '    <uses-permission android:name="android.permission.INTERNET" />',
            '    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />',
            '    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />'
        ) -join "`r`n"
        if ($xml -notmatch 'android.permission.INTERNET') {
            $xml = $xml -replace '(<manifest[^>]*>)', ('$1' + "`r`n" + $permissions)
        } else {
            if ($xml -notmatch 'ACCESS_COARSE_LOCATION') {
                $xml = $xml -replace '(<manifest[^>]*>)', ('$1' + "`r`n" + $permissions.Replace('    <uses-permission android:name="android.permission.INTERNET" />' + "`r`n", ''))
            }
        }
        $xml = $xml -replace 'android:label="[^"]+"', 'android:label="Barengin"'
        if ($xml -notmatch 'usesCleartextTraffic') {
            $xml = $xml -replace '<application', '<application android:usesCleartextTraffic="true"'
        }
        Set-Content -Path $manifest -Value $xml -Encoding UTF8
    }

    $gradleKts = Join-Path $projectRoot 'android/app/build.gradle.kts'
    $gradleGroovy = Join-Path $projectRoot 'android/app/build.gradle'
    if (Test-Path $gradleKts) {
        $gradle = Get-Content $gradleKts -Raw
        $gradle = $gradle -replace 'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 23'
        Set-Content -Path $gradleKts -Value $gradle -Encoding UTF8
    } elseif (Test-Path $gradleGroovy) {
        $gradle = Get-Content $gradleGroovy -Raw
        $gradle = $gradle -replace 'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 23'
        Set-Content -Path $gradleGroovy -Value $gradle -Encoding UTF8
    }

    Write-Host "Platform Android dan Web berhasil disiapkan." -ForegroundColor Green
    Write-Host "Selanjutnya jalankan: flutter pub get" -ForegroundColor Yellow
}
finally {
    if (Test-Path $seed) { Remove-Item $seed -Recurse -Force }
}
