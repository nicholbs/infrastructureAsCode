#!/bin/bash -v

#Defualt values
stackName="infraStack"
keyPairName="slettMeg"
stackNameClient="puppet-server"
stackNameAuto="autoScale"

#Check if keypair exists
finnesKeyPair=$(openstack keypair list --format json | grep "Name" -m 1 | awk '{print $2}' | tr -d '",')
if [ -z "$finnesKeyPair" ]
then
	echo "\$finnesKeyPair is empty"
	#Create a keypair for SSH between instances in project and put the private key into .ssh folder
	openstack keypair create $keyPairName > ~/.ssh/slettMeg
	chmod 700 ~/.ssh/slettMeg
else
	#Keypair existed, do not need to create another
	echo "\$finnesKeyPair is NOT empty"
	keyPairName=$(openstack keypair list --format json | grep "Name" -m 1 | awk '{print $2}' | tr -d '",')
	FILE=~/.ssh/$keyPairName
	if [ -f "$FILE" ]; 
	then
		echo "$FILE exists"
		#All went well
	else
		echo "$FILE does NOT exist"
		#TODO error handling: Keypair does not exist in .ssh folder of openstack client. cannot send the keypair to other instanses and enable ssh connection between them
		#NB! Resten av oppsettet avhenger per nå av at private delen av nøkkelen ligger i .ssh folderen 
		exit 1
	fi
fi	

#Create a stack from 'create-gitlab.yaml' template and send necessary parameters
openstack stack create --template  ~/infrastructureAsCode/create-gitlab.yaml -e ~/infrastructureAsCode/env-variables.yaml --parameter "keyPair_name=$keyPairName;stack_name=$stackName" $stackName

#Check wether the stack was created successfully or generated errors
ref="CREATE_COMPLETE"
stackStatus=$(openstack stack show $stackName --format json | jq '.stack_status' | tr -d '"')
while [ "$stackStatus" != "CREATE_COMPLETE" ]
do
sleep 30s
if [ "$stackStatus" == "$ref" ]; then
	echo "Stack creation is $loopFerdig"
else
    stackStatus=$(openstack stack show $stackName --format json | jq '.stack_status' | tr -d '"')
	echo "Not completed $loopFerdig"
    openstack stack event list $stackName
fi
done

#Check if folder to hold stack generated output for use of manager instance exists
DIR=~/infrastructureAsCode/manager/
if [ -d "$DIR" ]; then
  # Take action if $DIR exists. #
  echo "manager folder finnes ${DIR}"
else
	mkdir ~/infrastructureAsCode/manager/
fi

#Retrieve the URL created by Openstack API to scale the amount of gitlab servers down
openstack stack show $stackName --format json | grep 'scaledown' | awk '{getline; getline; print}' | awk '{print $2}' | tr -d '"' > ~/infrastructureAsCode/manager/scale_down_url

#Retrieve the URL created by Openstack API to scale the amount of gitlab servers upp
openstack stack show $stackName --format json | grep 'scaleup' | awk '{getline; getline; print}' | awk '{print $2}' | tr -d '"' > ~/infrastructureAsCode/manager/scale_up_url

#loop until the network from stack has been created, we cannot create further instances before the network exists
loopFerdig="false"
finnesInterntNettverk=$(openstack network list --format value | awk '{print $2}' | grep -v '^ntnu')
while [ "$loopFerdig" != "true" ]
do
sleep 5s
 if [ -z "$finnesInterntNettverk" ]
 then
	 finnesInterntNettverk=$(openstack network list --format value | awk '{print $2}' | grep -v '^ntnu')
 else
	 loopFerdig="true"
 fi
done


#Retrieve IP address of the manager instance created in the infrastructure stack
managerIP=$(openstack stack show $stackName -f json | jq '.outputs[0].output_value,.outputs' | awk '/Floating/{getline; print}' | awk '{print $2}' | tr -d '"')


#Send repository with management scripts to manager instance
scp -r -i ~/.ssh/$keyPairName ~/infrastructureAsCode/ ubuntu@$managerIP:/home/ubuntu/

#Send keypair to enable remote access to manager instance 
scp -i ~/.ssh/$keyPairName ~/.ssh/$keyPairName ubuntu@$managerIP:/home/ubuntu/.ssh/