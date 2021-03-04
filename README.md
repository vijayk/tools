# tools

Httpd service on master:

Error:

- You don't have permission to access /logs/ on this server.

Fix:

- Check /var/log/audit/audit.log

** type=AVC msg=audit(1614837138.767:1109): avc:  denied  { getattr } for  pid=15907 comm="httpd" path="/grid/0/hiveptest/logs/index.html" dev="vdc" ino=24903683 scontext=system_u:system_r:httpd_t:s0 tcontext=unconfined_u:object_r:unlabeled_t:s0 tclass=file permissive=0
  type=SYSCALL msg=audit(1614837138.767:1109): arch=c000003e syscall=6 success=no exit=-13 a0=55f480879dc0 a1=7ffc95e7b290 a2=7ffc95e7b290 a3=0 items=0 ppid=15901 pid=15907 auid=4294967295 uid=48 gid=48 euid=48 suid=48 fsuid=48 egid=48 sgid=48 fsgid=48 tty=(none) ses=4294967295 comm="httpd" exe="/usr/sbin/httpd" subj=system_u:system_r:httpd_t:s0 key=(null)

- chcon  --user system_u --type httpd_sys_content_t -Rv /var/www/html/logs/
