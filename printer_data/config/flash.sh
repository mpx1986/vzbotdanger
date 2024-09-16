#!/bin/bash

cd "$HOME/klipper"

rpi_flash(){
	echo -e "\033[1;34m\nStep 1: Cleaning and flashing Klipper to Raspberry Pi.\033[0m"
	make clean KCONFIG_CONFIG=config.rpi
	make flash KCONFIG_CONFIG=config.rpi -j4 > /dev/null 2>&1
}

octopus_flash(){
	echo -e "\033[1;34m\nStep 2: Cleaning and building Klipper firmware for Octopus.\033[0m"
	make clean KCONFIG_CONFIG=config.octopus
	make -s KCONFIG_CONFIG=config.octopus -j4  > /dev/null 2>&1
	mv ~/klipper/out/klipper.bin octopus_klipper.bin
	echo -e "\033[1;34m\nStep 3: Flashing Klipper to Octopus.\033[0m"
	python3 ~/katapult/scripts/flashtool.py -i can0 -u 59469bda118c -r
	sleep 5
	python3 ~/katapult/scripts/flash_can.py -f ~/klipper/octopus_klipper.bin -d /dev/serial/by-id/stm32h723xx_32001F000F51313531383332-if00
}

ebb36_flash(){
	echo -e "\033[1;34m\nStep 4: Cleaning and building Klipper firmware for ebb36.\033[0m"
	make clean KCONFIG_CONFIG=config.ebb36
	make -s KCONFIG_CONFIG=config.ebb36 -j4  > /dev/null 2>&1
	mv ~/klipper/out/klipper.bin ebb36_klipper.bin
	echo -e "\033[1;34m\nStep 5: Flashing Klipper to ebb36.\033[0m"
	python3 ~/katapult/scripts/flash_can.py -f ~/klipper/ebb36_klipper.bin -u 7923f36815fd
}


power_cycle(){
	echo -e "\033[1;34m\nCycling power to PSU and boards.\033[0m"
	curl -s -X POST "http://localhost:7125/machine/device_power/off?VZBot330" > /dev/null 2>&1
	sleep 5
	curl -s -X POST "http://localhost:7125/machine/device_power/on?VZBot330" > /dev/null 2>&1
	sleep 5

}

echo -e "\033[1;34m\nStopping Klipper service.\033[0m"
sudo service klipper stop

power_cycle

rpi_flash

power_cycle

octopus_flash

power_cycle

ebb36_flash

power_cycle

cartographer_flash

power_cycle

echo -e "\033[1;34m\nStarting Klipper service.\033[0m"
sudo service klipper start
