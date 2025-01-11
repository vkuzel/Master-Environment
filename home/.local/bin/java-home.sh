#!/bin/bash

version=$1
globalJavaDir=/usr/lib/jvm
userJavaDir=$HOME/.jdks

print_usage_and_exit() {
	echo
	echo "Usage: java-home.sh [VERSION]"
	echo
	echo "When VERSION is set, it tries to find Java home directory for the specified version in $globalJavaDir or $userJavaDir"
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


javaDirPattern="(java|corretto)-$version"
for file in $globalJavaDir/*
do
	foundJava=$(echo "$file" | grep -Eo "$javaDirPattern")
	if [[ ! -z "$foundJava" ]]; then
		echo $file
		exit
	fi
done

for file in $userJavaDir/*
do
	foundJava=$(echo "$file" | grep -Eo "$javaDirPattern")
	if [[ ! -z "$foundJava" ]]; then
		echo $file
		exit
	fi
done

echo "Cannot find Java $version in $globalJavaDir or $userJavaDir!"
print_usage_and_exit

