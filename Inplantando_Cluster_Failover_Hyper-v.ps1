# == COMANDOS EXECUTADOS NO NOTEBOOK HOST HYPER-V === #

#Criar um Variavel para Credencial de Dominmio e Workgroup para Usar o Powershell Direct nas VMS
$Creddm =  Get-Credential    #Dominio
$Credwg =  Get-Credential    #WorkGroup

#Ver todas as Vms no Hyper-v
Get-VM 

#Acessar remotamente Via Powershell as Vms usando as credenciais. 
Enter-PSSession -VMName LAB01_CLUSTERNODE1 

#Habilitar Virtualização Aninhada em Vms no Hyper-v
Set-VMProcessor -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2  -ExposeVirtualizationExtensions $true

#Ligar as VMS
Start-VM -Name LAB01_CLUSTERNODE1, LAB01_CLUSTERNODE2,DC-CLUSTER,LAB01_FILESTORAGE,LAB01_CLUSTER-MGMT

#Desligar as VM
Stop-VM -Name  LAB01_CLUSTERNODE1, LAB01_CLUSTERNODE2,DC-CLUSTER,LAB01_FILESTORAGE,LAB01_CLUSTER-MGMT

# Instalar Função Hyper-v nos Servidores do Cluster
Invoke-Command -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2 -Credential $Creddm -ScriptBlock { install-WindowsFeature Hyper-v, Failover-Clustering -IncludeAllSubfeature -IncludeManagementTools -Restart}

# Ver Quais Rsat Instão Instadas no Computador
Get-WindowsCapability -Name RSAT* -Online | Select-Object -Property DisplayName, State

#ou
Get-WindowsCapability -Name RSAT* -Online | Select-Object -Property Name, State

#Comando Direto na Maquina do DOMINO para Istalar RSAT (Exemplo abaixo, ADDS, DNS, DHCP, CERTIFICADO
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
Add-WindowsCapability -Online -Name Rsat.CertificateServices.Tools~~~~0.0.1.0
Add-WindowsCapability -Online -Name Rsat.DHCP.Tools~~~~0.0.1.0 
Add-WindowsCapability -Online -Name Rsat.Dns.Tools~~~~0.0.1.0 


#Instale o Console de Gerenciamento do Hyper-v na VM MGMT via Painel de Controle

#Instalando o RSAT de Failover Clustering no Windows 10

Invoke-Command -VMName LAB01_CLUSTER-MGMT -Credential $Creddm -ScriptBlock { Add-WindowsCapability -Online -Name Rsat.FailoverCluster.Management.Tools~~~~0.0.1.0}

#Ver Adaptadores de Rede das VMs Hyper-v

Get-VMNetworkAdapter -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2

#Adicionado mais Placas de Rede no Nós dos Cluster ( Adicionado 3x Placas de Rede em cada Host)

AAdd-VMNetworkAdapter -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2 -SwitchName "VmNAT2" -DeviceNaming On
AAdd-VMNetworkAdapter -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2 -SwitchName "VmNAT2" -DeviceNaming On
AAdd-VMNetworkAdapter -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2 -SwitchName "VmNAT2" -DeviceNaming On

#Habilitando Falsificação de Endereço MAC ( APENAS EM LAB)

Get-VMNetworkAdapter -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2 | Set-VMNetworkAdapter -MacAddressSpoofing On -AllowTeaming On

#Verificar as Placas de Rede dentro dos Servidores
Invoke-Command -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2  -Credential $Creddm -ScriptBlock { Get-NetAdapter | ft}

#Criando um Time de Placa de Rede Dentro do Host Hyper-v

Invoke-Command -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2  -Credential $Creddm -ScriptBlock { New-VMSwitch -Name Management -EnableEmbeddedTeaming $true -NetAdapterName "Ethernet","Ethernet 2","Ethernet 3","Ethernet 4" }

#Ver endereços Ips de Rede Adicionados a Equipe de Placa de Rede

Invoke-Command -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2  -Credential $Creddm -ScriptBlock { Get-NetIPAddress | ft interfacealias, ipaddress}

#Adicionando mais Adaptaodres de Redes Virtuais aos Nós do Cluster
Invoke-Command -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2  -Credential $Creddm -ScriptBlock { Add-VMNetworkAdapter -ManagementOS -Name "Cluster" -SwitchName Management}
Invoke-Command -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2  -Credential $Creddm -ScriptBlock { Add-VMNetworkAdapter -ManagementOS -Name "Storage" -SwitchName Management}

#Atribuindo Endereços IPs ao Adaptadores de Rede
Invoke-Command -VMName LAB01_CLUSTERNODE1 -Credential $Creddm -ScriptBlock { New-NetIPAddress -InterfaceAlias "vEthernet (Cluster)" -IPAddress 10.0.0.1 -PrefixLength 24}
Invoke-Command -VMName LAB01_CLUSTERNODE1 -Credential $Creddm -ScriptBlock { New-NetIPAddress -InterfaceAlias "vEthernet (Storage)" -IPAddress 10.0.1.1 -PrefixLength 24}
Invoke-Command -VMName LAB01_CLUSTERNODE2 -Credential $Creddm -ScriptBlock { New-NetIPAddress -InterfaceAlias "vEthernet (Cluster)" -IPAddress 10.0.0.2 -PrefixLength 24}
Invoke-Command -VMName LAB01_CLUSTERNODE2 -Credential $Creddm -ScriptBlock { New-NetIPAddress -InterfaceAlias "vEthernet (Storage)" -IPAddress 10.0.1.2 -PrefixLength 24}

#Acesse Remoto os Servidores e Teste as Comunicações

Enter-PSSession -VMName LAB01_CLUSTERNODE1 -Credential $Creddm

#Instale o Windows Admin Center na VM de Gerenciamento 
#Acesse o Windwos Admin Center e Veja os Adaptadores e Algoritimo de Balanceamento do NICTEAM


#Alterar o Algoritimo de Balanceamento do NICTEAM

Invoke-Command -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2  -Credential $Creddm -ScriptBlock { Set-VMSwitchTeam -Name Management -LoadBalancingAlgorithm Dynamic }

#Adicionado uma Placa de Rede no Storage VM

Add-VMNetworkAdapter -VMName LAB01_FILESTORAGE -SwitchName "VmNAT2" -DeviceNaming On

#Atribuindo endereço IP a VM do STORAGE

Invoke-Command -VMName LAB01_FILESTORAGE -Credential $Credwg -ScriptBlock { New-NetIPAddress -InterfaceAlias "Ethernet 2" -IPAddress 10.0.1.100 -PrefixLength 24}

#Ver as Placas de Rede Dentro da VM Storage

Invoke-Command -VMName LAB01_FILESTORAGE -Credential $Credwg -ScriptBlock { Get-NetAdapter | ft}

#Ver os Endereços Ips dentro da Maquina Virtual Storage
Invoke-Command -VMName LAB01_FILESTORAGE -Credential $Credwg -ScriptBlock { Get-NetIPAddress | ft interfacealias, ipaddress}



#Instalando o Recurso de Servidor de Destino ISCSI no VM LAB01_FILESTORAGE

Invoke-Command -VMName LAB01_FILESTORAGE -Credential $Credwg -ScriptBlock { Install-WindowsFeature FS-FileServer,FS-iSCSITarget-Server -IncludeAllSubfeature -IncludeManagementTools -Restart}


#Ativando o Serviço do Iniciador ISCSI Para Se Conectar ao Storage
Invoke-Command -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2  -Credential $Creddm -ScriptBlock { Set-Service msiscsi -StartupType Automatic ; Start-Service msiscsi}

#Descobrindo qual o Nome de Porta do Meu Iniciador Iscsi
Invoke-Command -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2  -Credential $Creddm -ScriptBlock { Get-InitiatorPort}

#Definindo Porta de Destino ISCSI para os Servidores Nó do Cluster
Invoke-Command -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2  -Credential $Creddm -ScriptBlock { New-IscsiTargetPortal -TargetPortalAddress 10.0.1.100}

#Adicione o Disco Virtual de 200GB a VM LAB01_FILESOTRAGE para Servir de Armazenamento dos Discos Iscsi

#Criando as Luns no FILESTORAGE ( Disco de Quorum) NAO DEU CERTO
Invoke-Command -VMName LAB01_FILESTORAGE -Credential $Credwg -ScriptBlock { New-iSCSIVirtualDisk -Path "D:\ISCSI\iscsi-Quorun.vhdx" -Description "Iscsi-Quorun" -Size 10GB}
Invoke-Command -VMName LAB01_FILESTORAGE -Credential $Credwg -ScriptBlock { New-ISCSIServerTarget -TargetName "iscsi-target1" -InitiadorIds @("IPAddress:10.0.1.1","IPAddress:10.0.1.2"}
Invoke-Command -VMName LAB01_FILESTORAGE -Credential $Credwg -ScriptBlock { Add-iSCSIVirtualDiskTargetMapping -TargnetName "iscsi-target1" -Path "D:\ISCSI\iscsi-Quorun.vhdx"}


#Atualizando o Portal Iscsi no Servidores Hyper-v para idenficar os discos.
Invoke-Command -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2  -Credential $Creddm -ScriptBlock { Get-IscsiTargetPortal | Update-IscsiTargetPortal}

# Nos Hosts hyper-v Ver destinos do Iscsi Target
Invoke-Command -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2  -Credential $Creddm -ScriptBlock { Get-IscsiTarget}

#Conectando os Hosts Hyper-v ao Distino Iscsi do FILESTORAGE
Invoke-Command -VMName LAB01_CLUSTERNODE1 -Credential $Creddm -ScriptBlock { Connect-IscsiTarget -NodeAddress iqn.1991-05.com.microsoft:filestorage-servidores-cluster-target -IsPersistent $true -InitiatorPortalAddress 10.0.1.1 -TargetPortalAddress 10.0.1.100}
Invoke-Command -VMName LAB01_CLUSTERNODE2 -Credential $Creddm -ScriptBlock { Connect-IscsiTarget -NodeAddress iqn.1991-05.com.microsoft:filestorage-servidores-cluster-target -IsPersistent $true -InitiatorPortalAddress 10.0.1.2 -TargetPortalAddress 10.0.1.100}

#Registrar o Portal Iscsi nos Hosts Hyper-v

Invoke-Command -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2 -Credential $Creddm -ScriptBlock { Get-IscsiSession | Register-IscsiSession}


#Abra o Server Manager na VM Win10 MGMT e Adicione todos os Servidores para Gerenciar.

#Abra o Server Manager e Va em Discos e Coloque os Discos Recebidos pelo servidor File Storage no Servidor CLUSTERNODE1

#Conectado no Server Mnager Inicialize os Discos no Servidor CLUSTERNODE1

#Conectado no Server Mnager Crie um Volume Pequeno (UNIDADE Q:\  Para ser usado como Disco de Quorum no Servidor CLUSTERNODE1

#Agora sim Vamos a VM-WIN10-MGMT e Abra o Console do Gerenciamento de Cluster e Faça a validação do Cluster

#CRIANDO O CLUSTER DE FAILOVER #Executar a Partir da VM MGMT
New-Cluster -Name cluster-a -Node CLUSTERNODE1,CLUSTERNODE2 -StaticAddress 192.168.180.10

#Adicione novos Discos de Dados ao Cluster


#Instalando o Recurso de DHCPSERVER Nos Do Cluster para usar como exemplo de função de Servidor DHCP Clusterizada

Invoke-Command -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2 -Credential $Creddm -ScriptBlock { Install-WindowsFeature dhcp}

#Acesse o Gerenciamento do Cluster e Cria a Função DHCP-Server

#Instalando a Função de Servidor de Arquivos nós nODES DO cLUSTER

Invoke-Command -VMName LAB01_CLUSTERNODE1,LAB01_CLUSTERNODE2 -Credential $Creddm -ScriptBlock { Install-WindowsFeature fs-fileserver}

#Adicione um Novo Disco de Armazenamento Ao Cluster para as VMS.































# == COMANDOS EXECUTADOS DENTRO DA VM WIN10 MGMT EM AMBIENTE DE DOMINIO === #

Install-WindowsFeature -ComputerName FILESTORAGE FS-FileServer,FS-iSCSITarget-Server -IncludeAllSubfeature -IncludeManagementTools -Restart



