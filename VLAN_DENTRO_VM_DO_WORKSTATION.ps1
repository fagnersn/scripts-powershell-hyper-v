#PROCEDIMENTO PARA TAGUEAR VLAN DENTRO DE UMA VIRTUAL MACHINE WIN10, WIN11 GUEST NO VMWARE WORKSTATION

#(1)  #Instalar o Hyper-v na VM# 
Install-WindowsFeature -Name Hyper-v -IncludeAllSubFeature -IncludeManagementTools -Restart

#(2)  #Descubra o Nome do seu adaptador de Rede# 
Get-NetAdapter 

#(3)  #Crie o Switch Virtual no Hyper-v#
New-VMSwitch -Name "VLAN-Tagging-Switch" -NetAdapterName Ethernet0 -AllowManagementOS $true

#(4)  #Criando um  Adaptador de Rede com a Vlan Embedada#
Add-VMNetworkAdapter -ManagementOS -Name "MYVLAN-TAG" -SwitchName "VLAN-Tagging-Switch" -Passthru | Set-VMNetworkAdapterVlan -Access -VlanId 10 

#(5) #Destruir o Adapotador com a Vlan Embedada, Para setar uma Nova Vlan Crie um Novo Adaptador de Rede com Vlan embedada repetindo o passo 3.
Remove-VMNetworkAdapter -Name "MYVLAN-TAG" -ManagementOS  

#(6) Destruir do Switch Principal dp Hyper-v ( So use se necessario) 
Remove-VMSwitch -Name "VLAN-Tagging-Switch"
