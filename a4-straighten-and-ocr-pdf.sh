#!/bin/bash

#TOOD: set a parameter for the language (used in ocr)

set -x
pagecount=$(pdfinfo "$1" | grep Pages | sed 's/[^0-9]*//')

echo pagecount: $pagecount
# convert every page individually to a4 pdf size
# (and thereby stretch/shrink each pdf page individually)
for i in $(seq 1 $pagecount)
do
    echo $i
    printf -v j "%05.f" $i
    pdfjam $1 $i --a4paper --outfile a4ed-${j}.pdf
done

# join the pdf together
echo joining the a4ed pages back together to one pdf
pdfjam a4ed-*.pdf -o a4ed-joined.pdf

# convert it to individual pngs to process each page
# it's automatically named so that the files are in alphabetical order
echo "pdftoppm(actually to png)-ing the large a4ed joined document into png pages"
pdftoppm a4ed-joined.pdf pnged -png

# use unpaper to deskew each page individually
i=1
for filename in $(ls pnged*); do
    printf -v iformatted "%05.f" $i  # make sure to stick with this format later on
    echo unpapering: page $i of $pagecount
    unpaper $filename unpapered-$iformatted.pnm
    i=$(( $i + 1 ))
done


# use convert (imagemagick) to convert the pnm files to tif files,
# because tesseract really likes to work with the tif format for OCR
for i in $(seq --format=%05.f 1 $pagecount); do  # use the format defined above
  echo converting to tiff format: page $i of $pagecount
  convert unpapered-$i.pnm tiffed-$i.tif
done


# run tesseract to do ocr and simultaneously convert to pdf
for i in $(seq --format=%05.f 1 $pagecount); do  # use the format defined above
    echo tesseracting: page $i of $pagecount, language: eng
    tesseract -l eng tiffed-$i.tif tesseracted-$i pdf
done


# join them back up
echo joining the tesseracted pdfs up
pdfjam tesseracted-*.pdf -o tesseracted-joined.pdf

set +x
exit
