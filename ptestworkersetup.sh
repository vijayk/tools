#!/bin/bash

workers=(\
10.64.16.84 \
10.64.16.95 \
10.64.16.48 \
10.64.16.82 \
10.64.16.77 \
10.64.16.52 \
10.64.16.47 \
10.64.16.62 \
10.64.16.76 \
10.64.16.73
)

submitKey(){
        for worker in ${workers[@]}; do
                echo "Submitting to $worker"
                #ssh -i /root/.ssh/hw-re-keypair.pem root@${worker} "date"
                scp -o StrictHostKeyChecking=no -i /root/.ssh/hw-re-keypair.pem /root/.ssh/id_rsa.pub root@${worker}:/tmp && ssh -i /root/.ssh/hw-re-keypair.pem root@${worker} "cat /tmp/id_rsa.pub >> /root/.ssh/authorized_keys"
                [ "$?" == 0 ] && echo "Submit success for $worker..."
        done
}

createUser(){
        for worker in ${workers[@]}; do
                echo "creating user hiveptest on $worker"
                ssh -i ~/.ssh/hw-re-keypair.pem root@${worker} "useradd -m -U -d /home/hiveptest hiveptest" && ssh -i ~/.ssh/hw-re-keypair.pem root@${worker} "echo hiveptest:hiveptest| chpasswd"
                [ "$?" == 0 ] && echo "User hiveptest created on $worker..."
        done
}

submituserKey(){
        for worker in ${workers[@]}; do
                echo "Submitting to $worker"
                if ( scp -i ~/.ssh/hw-re-keypair.pem /home/hiveptest/.ssh/hive-ptest-user-key.pub root@${worker}:/tmp ); then
                        ssh -i ~/.ssh/hw-re-keypair.pem root@${worker} \
                        "mkdir /home/hiveptest/.ssh ; \
                        chmod 700 /home/hiveptest/.ssh ; \
                        cat /tmp/hive-ptest-user-key.pub >> /home/hiveptest/.ssh/authorized_keys ; \
                        chown -R hiveptest.hiveptest /home/hiveptest/.ssh ; \
                        chmod 600 /home/hiveptest/.ssh/authorized_keys"
                else
                        echo "Key copy failed for user!!!"
                fi
        done
}

pushTools(){
        for worker in ${workers[@]}; do
                echo "Pushing to $worker"
                if ( scp -i /home/hiveptest/.ssh/hive-ptest-user-key /home/hiveptest/software/build-tools-new.tar.gz hiveptest@${worker}:/home/hiveptest  ); then
                        ssh -i /home/hiveptest/.ssh/hive-ptest-user-key hiveptest@${worker} \
                        "tar -zxvf build-tools-new.tar.gz > /dev/null 2>&1"
                else
                        echo "Tools copy failed!!!"
                fi
        done
}

pushConf(){
        for worker in ${workers[@]}; do
                echo "Pushing conf to $worker"
                if ( scp -i /home/hiveptest/.ssh/hive-ptest-user-key /home/hiveptest/.m2/settings.xml hiveptest@${worker}:/tmp > /dev/null 2>&1 ); then
                ssh -i /home/hiveptest/.ssh/hive-ptest-user-key hiveptest@${worker} \
                "[ -d /home/hiveptest/.m2 ] || mkdir /home/hiveptest/.m2 ; \
                cp -f /tmp/settings.xml /home/hiveptest/.m2"
                else
                        echo "Configurations copy failed!!!"
                fi
        done
}

updateBashrc(){
	for worker in ${workers[@]}; do
		echo "Updating bashrc on $worker"
		if ( scp -i /home/hiveptest/.ssh/hive-ptest-user-key /root/rc hiveptest@${worker}:/tmp > /dev/null 2>&1 ); then
			ssh -i /home/hiveptest/.ssh/hive-ptest-user-key hiveptest@${worker} \
			"cat /tmp/rc >> /home/hiveptest/.bashrc"
		fi
	done
}

updateLimit(){
    # change need restart of the node.
    for worker in ${workers[@]}; do
            echo "Pushing conf to $worker"
        	ssh -i ~/.ssh/hw-re-keypair.pem root@${worker} \
        	"echo -e 'hiveptest\tsoft\tnproc\t376907' >> /etc/security/limits.conf ; \
         	echo -e 'hiveptest\thard\tnproc\t376907' >> /etc/security/limits.conf"
    done
}

addSwap() {
    for worker in ${workers[@]}; do
         echo "Pushing swap to $worker"
         ssh -i ~/.ssh/hw-re-keypair.pem root@${worker} \
	"test -f /swapfile || rm -f /swapfile ; \
         dd if=/dev/zero of=/swapfile count=4096 bs=2MiB ; \
         chmod 600 /swapfile ; \
         mkswap /swapfile ; \
         swapon /swapfile ; "
         echo -e '/swapfile\t\tswap\t\t\tswap\tdefaults\t0 0' >> /etc/fstab;"
    done
}

cleanHome(){
	    for worker in ${workers[@]}; do
            	echo "Cleaning $worker"
       		 ssh -i ~/.ssh/hw-re-keypair.pem root@${worker} \
		"rm -rf /home/hiveptest/{apache-tomcat-7.0.41,build-tools-new.tar.gz,template_profile_autosync,test-properties}"
	done
}

#main
#submitKey
#createUser
#submituserKey
#pushTools
#pushConf
#updateBashrc
#pushJdk
#updateLimit
#addSwap
#cleanHome
