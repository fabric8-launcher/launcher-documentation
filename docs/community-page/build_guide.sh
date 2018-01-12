
#Name of the html output file
GUIDE_HTML_NAME=index.html
OUTPUT_DIR=../../html

rm -r $OUTPUT_DIR/docs/images/
cp -r topics/images/ $OUTPUT_DIR/docs/images/

asciidoctor master.adoc -o $OUTPUT_DIR/$GUIDE_HTML_NAME