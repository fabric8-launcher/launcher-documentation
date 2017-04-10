
#Name of the html output file
GUIDE_HTML_NAME=mission-crud-vertx.html
OUTPUT_DIR=../../html

rm -r $OUTPUT_DIR/images/
cp -r topics/images/ $OUTPUT_DIR/images/

asciidoctor master.adoc -o $OUTPUT_DIR/$GUIDE_HTML_NAME
