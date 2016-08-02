#!/bin/bash

#scp -i .ssh/hw-re-keypair.pem .ssh/id_rsa.pub root@172.22.106.14:/tmp ; ssh root@172.22.106.14 "cat /tmp/id_rsa.pub >> /root/.ssh/authorized_keys"


workers=(\
172.22.111.144 \
172.22.111.136 \
172.22.111.1 \
172.22.111.0 \
172.22.110.97 \
172.22.110.89 \
172.22.110.88 \ 
172.22.110.87 \
172.22.110.82 \
172.22.110.46 \
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
                ssh root@${worker} "useradd -m -U -d /home/hiveptest hiveptest" && ssh root@${worker} "echo hiveptest:hiveptest| chpasswd"
                [ "$?" == 0 ] && echo "User hiveptest created on $worker..."
        done
}

submituserKey(){
        for worker in ${workers[@]}; do
                echo "Submitting to $worker"
                if ( scp /home/hiveptest/.ssh/hive-ptest-user-key.pub root@${worker}:/tmp ); then
                        ssh root@${worker} \
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
                #echo "export JAVA_HOME="/home/hiveptest/tools/jdk7/latest"" >> /home/hiveptest/.bashrc ; \
                #echo "export MVN_HOME="/home/hiveptest/tools/maven/latest"" >> /home/hiveptest/.bashrc ; \
                #echo "" >> /home/hiveptest/.bashrc ; \
                #echo "export PATH="$JAVA_HOME/bin:$MVN_HOME/bin:$PATH"" >> /home/hiveptest/.bashrc"
                else
                        echo "Configurations copy failed!!!"
                fi
                exit 0
        done
}

updateLimit(){
	for worker in ${workers[@]}; do
        	echo "Pushing conf to $worker"
		ssh root@${worker} \
		"echo -e 'hiveptest\tsoft\tnproc\t376907' >> /etc/security/limits.conf ; \
		 echo -e 'hiveptest\thard\tnproc\t376907' >> /etc/security/limits.conf"
	done	
}

addSwap() {
	for worker in ${workers[@]}; do
        	echo "Pushing swap to $worker"
		ssh root@${worker} \
		"fallocate -l 64G /swapfile ; \
		 chmod 600 /swapfile ; \
		 mkswap /swapfile ; \
		 swapon /swapfile ; \
		 echo -e '/swapfile\t\tswap\t\t\tswap\tdefaults\t0 0' >> /etc/fstab;"
	done	
	
}

#main
#submitKey
#createUser
#submituserKey
#pushTools
#pushConf
#pushJdk
#updateLimit
addSwap
