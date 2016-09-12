for i in `find . -type d -name manifests`
do 
  list=`find $i -type f -name "*.txt"`

  for file in $list; do 
    sed -i -e '/-monarch_jar_version/d' -e 's#\(^buildsupport.*| \).*$#\1754851b42a646d27ae31fd19f7dc4bad5bd1d658#' -e 's@\(^teradata_connector.*| \).*$@\14f5cfe2dadb8d43e22ddb677da912f72977b4576@' $file
  done
done