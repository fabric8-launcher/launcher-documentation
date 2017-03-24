
#Name of the html output file
GUIDE_HTML_NAME=minishift-installation.html

asciidoctor master.adoc -o ../../html/$GUIDE_HTML_NAME
