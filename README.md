# tools

Httpd service on master:

Error:

- You don't have permission to access /logs/ on this server.

Fix:

- Check /var/log/audit/audit.log

** type=AVC msg=audit(1614837138.767:1109): avc:  denied  { getattr } for  pid=15907 comm="httpd" path="/grid/0/hiveptest/logs/index.html" dev="vdc" ino=24903683 scontext=system_u:system_r:httpd_t:s0 tcontext=unconfined_u:object_r:unlabeled_t:s0 tclass=file permissive=0
  type=SYSCALL msg=audit(1614837138.767:1109): arch=c000003e syscall=6 success=no exit=-13 a0=55f480879dc0 a1=7ffc95e7b290 a2=7ffc95e7b290 a3=0 items=0 ppid=15901 pid=15907 auid=4294967295 uid=48 gid=48 euid=48 suid=48 fsuid=48 egid=48 sgid=48 fsgid=48 tty=(none) ses=4294967295 comm="httpd" exe="/usr/sbin/httpd" subj=system_u:system_r:httpd_t:s0 key=(null)

- chcon  --user system_u --type httpd_sys_content_t -Rv /var/www/html/logs/

Refer : https://superuser.com/questions/882594/permission-denied-because-search-permissions-are-missing-on-a-component-of-the-p

Usually the execute permission for one path is not set, like it was in this question. The easiest way to solve this is the following command:

chmod a+rX -R /var/www
But on using CentOS7 or RHEL7 you might encounter problems with SELinux. If file permission are right and you still get the error, look at the following log:

tail -f /var/log/audit/audit.log
If you get a message like this:

type=AVC msg=audit(1464350432.916:8222): avc:  denied  { getattr } for  pid=17526 comm="httpd" path="/var/www/app/index.html" dev="sda1" ino=42021595 scontext=system_u:system_r:httpd_t:s0 tcontext=unconfined_u:object_r:var_t:s0 tclass=file
type=SYSCALL msg=audit(1464350432.916:8222): arch=c000003e syscall=4 success=no exit=-13 a0=7fde4e450d40 a1=7ffd05e79640 a2=7ffd05e79640 a3=7fde42e43792 items=0 ppid=17524 pid=17526 auid=4294967295 uid=48 gid=48 euid=48 suid=48 fsuid=48 egid=48 sgid=48 fsgid=48 tty=(none) ses=4294967295 comm="httpd" exe="/usr/sbin/httpd" subj=system_u:system_r:httpd_t:s0 key=(null)
This means: SELinux blocks the access to your document root. You can try a command like this (Recursive and verbose on option -Rv):

chcon  --user system_u --type httpd_sys_content_t -Rv /var/www/app/public
To find the right settings, look into a working directory like /var/www/html with this:

ls -laZ /var/www/
It should look like:

drwxr-xr-x. server server system_u:object_r:httpd_sys_content_t:s0 .
drwxr-xr-x. root   root   system_u:object_r:var_t:s0       ..
drwxr-xr-x. server server system_u:object_r:httpd_sys_script_exec_t:s0 cgi-bin
drwxr-xr-x. server server system_u:object_r:httpd_sys_content_t:s0 html
drwxrwxr-x. server server unconfined_u:object_r:var_t:s0   app

