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
	echo
	echo "Available Java installations:"
	list_java_installations "$globalJavaDir" | sed 's/^/  /'
	list_java_installations "$userJavaDir" | sed 's/^/  /'
	exit 1
}

java_dir_pattern() {
  echo "(java|corretto|jdk)-"
}

list_java_installations() {
  local javaDir="$1"

  local javaDirPattern
  javaDirPattern=$(java_dir_pattern)
  for file in "$javaDir"/*; do
    if echo "$file" | grep -Eq "$javaDirPattern"; then
      echo "$file"
    fi
  done
}

find_java() {
  local version=$1
  local javaDir="$2"

  local javaDirPattern
  javaDirPattern="$(java_dir_pattern)$version"
  for file in $(list_java_installations "$javaDir"); do
    local foundJava
    foundJava=$(echo "$file" | grep -Eo "$javaDirPattern")
    if [[ -n "$foundJava" ]]; then
      echo "$file"
      exit
    fi
  done
}

if [[ -z "$version" ]]; then
	if [[ -z "$JAVA_HOME" ]]; then
		echo "JAVA_HOME environment variable is not set!"
		print_usage_and_exit
	else
		echo "$JAVA_HOME"
		exit
	fi
fi

find_java "$version" "$globalJavaDir"
find_java "$version" "$userJavaDir"

echo "Cannot find Java $version in $globalJavaDir or $userJavaDir!"
print_usage_and_exit

