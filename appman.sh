#!/bin/bash

menuselect=0
zoneselect=0
ipprodfile="ipprod"
ipdevfile="ipdev"
ip_prod=""
ip_dev=""
cathome="/usr/local/tomcat/latest/"

menu(){
 select=$(whiptail --title "Operation Selection"  --cancel-button "back" --menu "Choose your operation" 15 50 4 \
  "1" "Deploy WAR file" \
  "2" "UnDeploy War file" \
  "3" "Download War file" \
   3>&1 1>&2 2>&3)
 exitstatus=$?
 menuselec=$select
 if [[ $select == 1 ]]; then
        deploy
 elif [[ $select == 2 ]]; then
        undeploy
 elif  [[ $select == 3 ]]; then
        download
 else
        main
 fi
}

production(){
 menu
}

develop(){
 menu 
}

setcathome(){
 cathome=$(whiptail --title "Download War File" --inputbox "Enter Catalina Home Directory:" 10 60 ${cathome}  3>&1 1>&2 2>&3)
 if [[ -z "$cathome" ]]; then
   whiptail --title "ERROR" --msgbox "Please Enter Catalina Home Directory!!!" 10 25
   setcathome
 fi
}

download(){
 unset menuitem
 case $zoneselect in
      1)
        ipfile=$ipprodfile
        appdir="webapps";;
      2)
        ipfile=$ipdevfile
        appdir="webtest";;
    esac
    existapp=0
    findappip=""
 srv=`head -1 $ipfile`
 findappip="$(cut -d ":"  -f 1 <<< $srv)"
 checkapp="curl -v --silent -u deployer:deployer http://${srv}/manager/text/list" #| cut -d ':' -f1 | grep -v List"
 applist=$( $checkapp 2>/dev/null | cut -d ':' -f1 | grep -v List )
 tmp=$(echo ${applist} | sed -e "s/\///g")
 IFS=':' read -ra rr <<< "$tmp"
 arr=($(echo $tmp | tr " " "\n"))

 for ((i=0; i<${#arr[@]}; i++))
 do
   menuitem+=("$((i))" "${arr[$i]}" )
 done

 pp=$(whiptail --title "Download Application"  --cancel-button "back" --menu "Choose application to download" 20 50 10 \
        "${menuitem[@]}" \
         3>&1 1>&2 2>&3)
 exitstatus=$?
 
 if [[ "$exitstatus" = 0  ]]; then
   appname="${menuitem[$(((pp*2)+1))]}"
   setcathome
   if [[ "${cathome: -1}" == "/" ]]; then
        cathometmp="${cathome::-1}"
   fi
   scpcmd="scp root@${findappip}:${cathometmp}/${appdir}/${appname}.war ."
   $scpcmd
  fi
 main 
}

undeploy(){
 appname=$(whiptail --title "UnDeploy Application" --inputbox "Enter Application name" 10 60  3>&1 1>&2 2>&3)
 case $zoneselect in
    1)ipfile=$ipprodfile;;
    2)ipfile=$ipdevfile;;
  esac
  while IFS= read -r line
  do
    srvip="$(cut -d ":"  -f 1 <<< $line)"
    msg="undeploy war file on server ${srvip} please wait..."
    columnas=$(tput cols)
    y=$((($columnas-${#msg})/2))
    x=0
    tput clear
    tput cup $x $y
    addrundeploy="http://${line}/manager/text/undeploy?path=/${appname}"
    echo $addrundeploy
    whiptail --textbox /dev/stdin 15 55 <<<  "$(curl -v -u deployer $addrundeploy)"
    echo  -e "\033[33;7m ${msg}\033[0m "
  done < "$ipfile"

 main 
}

deploy(){
 warfile=$(whiptail --title "Deploy War File" --inputbox "Enter .war file:" 10 60  3>&1 1>&2 2>&3)
 tmpapp="$(cut -d "."  -f 1 <<< $warfile)" 
 appname=$(whiptail --title "Deploy War File" --inputbox "Enter Application name:" 10 60 ${tmpapp} 3>&1 1>&2 2>&3)
 setcathome
 tomcatuser=$(whiptail --title "Deploy War File" --inputbox "Enter Tomcat Username:" 10 60 deployer  3>&1 1>&2 2>&3)
 tomcatpass=$(whiptail --title "Deploy War File" --passwordbox  "Enter Tomcat Password:" 10 60 deployer 3>&1 1>&2 2>&3)  
 cpcmd="cp deploy.xml ${appname}.xml"
  $cpcmd
  case $zoneselect in
    1)
	ipfile=$ipprodfile
	apphome="webapps";;
    2)
	ipfile=$ipdevfile
	apphome="webtest";;
  esac
  sedmyapp="sed -i s/_myapp_/${appname}/g ${appname}.xml"
  $sedmyapp
  if [[ "${cathome: -1}" == "/" ]]; then
       cathometmp="${cathome::-1}"
  fi
  cathometmp=$(echo ${cathometmp} | sed -e "s#/#\\\/#g")
  sedcathome="sed -i s/_cathome_/${cathometmp}/g ${appname}.xml"
  $sedcathome
  sedapphome="sed -i s/_apphome_/${apphome}/g ${appname}.xml"
  $sedapphome
  while IFS= read -r line
  do
    scpip="$(cut -d ":"  -f 1 <<< $line)"
    msg="deploy war file on server ${scpip} please wait..."
    columnas=$(tput cols)
    y=$((($columnas-${#msg})/2))
    x=0
    tput clear
    tput cup $x $y
    
    echo  -e "\033[33;7m ${msg}\033[0m "
    addr="http://${line}/manager/text/deploy?path=/${appname}&update=true"
    whiptail --textbox /dev/stdin 15 55 <<<  "$(curl -s -v --silent -u $tomcatuser:$tomcatpass  -T ./$warfile $addr)"
    scp ${appname}.xml root@${scpip}:/usr/local/tomcat/latest/conf/Catalina/localhost/
    addrstart="http://${line}/manager/text/start?path=/${appname}"
    curl -v -u  $tomcatuser:$tomcatpass $addrstart
  done < "$ipfile"
  rmcmd="rm -r ${appname}.xml"
  $rmcmd
 main 
}

about(){
  whiptail --title "About"  --msgbox "Apache Tomcat Application Manager Console\n\n\nDeveloped by Hamid.Lotf\nHamid.lotfi@gmail.com" 15 50
  main 
}

main(){
  zone=$(whiptail --title "Zone Selection"  --cancel-button "exit" --menu "Choose your Zone" 15 50 3 \
        "1" " Production Zone" \
        "2" " Development Zone" \
	"3" " About" \
	 3>&1 1>&2 2>&3)
  exitstatus=$?  
  zoneselect=$zone
	  case $zone  in
	    1) production;;
	    2) develop;;
	    3) about;;
	    *)  echo -e "\033[0m";exit ;;
	  esac
}

main
