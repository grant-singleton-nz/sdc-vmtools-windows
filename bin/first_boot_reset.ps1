# Generate new SID if needed
Start-Process -FilePath "C:\Windows\System32\Sysprep\SetSID.exe" -Wait

# Regenerate SSH host keys
Remove-Item -Path "$env:ProgramData\ssh\ssh_host_*" -Force
& "$env:ProgramData\ssh\ssh-keygen.exe" -A
Restart-Service sshd