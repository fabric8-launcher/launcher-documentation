GUIDE_HTML_NAME=nodejs-runtime.html
OUTPUT_DIR=../../html/docs

rm -r $OUTPUT_DIR/images/
cp -r topics/images/ $OUTPUT_DIR/images/

asciidoctor master.adoc -o $OUTPUT_DIR/$GUIDE_HTML_NAME
