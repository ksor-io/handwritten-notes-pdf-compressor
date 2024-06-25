# Handwritten notes PDF compressor.
This tool lets you compress PDFs right from file explorer & desktop using a context menu button. Built with files exported from GoodNotes in mind. Only tested on Windows.

## Install
1) Download & install [Ghostscript](https://ghostscript.com/releases/gsdnld.html).
2) Download & install [ImageMagick](https://imagemagick.org/script/download.php).
3) Download this tool by clicking "main.cmd" under [Releases](https://github.com/ksor-io/handwritten-notes-pdf-compressor/releases).
4) Run the downloaded file as admin (right click on the file -> run as admin).

## Usage
Go to `C:\Users\<your user name>\AppData\Roaming\NotesCompressor` and edit the `settings.txt` file to your liking. For example, if you want your files to be compressed to under 700KB, change `"threshold=700"` and `"thresholdUnit=KB"`. Note that smaller file sizes will probably come at a cost of quality.
Now you can right click on any PDF > `Show more options` > `Compress this file` and you will have a compressed file in no time.

## Disclaimer
This tool was built with handwritten notes written in GoodNotes in mind, which means if your file has an outline, links or little hand-written text, this tool will probably not suit your needs. **Always check the compressed file!**
