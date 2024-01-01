#!/bin/bash

version=$1
libDir=/usr/lib/jvm

print_usage_and_exit() {
	echo
	echo "Usage: java-home.sh [VERSION]"
	echo
	echo "When VERSION is set, it tries to find Java home directory for the specified version in the $libDir"
	echo "Otherwise prints the JAVA_HOME environment variable"
	echo "Prints error with this message if above options fails"
	exit 1
}

if [[ -z "$version" ]]; then
	if [[ -z "$JAVA_HOME" ]]; then
		echo "JAVA_HOME environment variable is not set!"
		print_usage_and_exit
	else
		echo $JAVA_HOME
		exit
	fi
fi


requestedJava="java-$version"
for file in $libDir/*
do
	foundJava=$(echo "$file" | grep -Eo "java-[0-9]{2}")
	if [[ "$requestedJava" == "$foundJava" ]]; then
		echo $file
		exit
	fi
done

echo "Cannot find Java $version in $libDir!"
print_usage_and_exit

