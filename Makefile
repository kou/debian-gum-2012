SOURCE:=$(wildcard debianmeeting*.tex)
DVIFILES:=$(SOURCE:%.tex=%.dvi)
PDFFILES:=$(SOURCE:%.tex=%.pdf)
RELEASEFILES:=$(SOURCE:%.tex=%.release-stamp)

IMAGES =					\
	images/normal-timer-ui.eps		\
	images/rabbit-timer-ui.eps

# server which hosts files for alioth.
all: $(PDFFILES)

check: all

%.pdf: %.dvi
	umask 002 ; dvipdfmx -o $@.tmp $< 
	mv $@.tmp $@

debianmeeting.tex: utf8-debianmeeting.tex $(IMAGES)
	iconv -f utf-8 -t iso-2022-jp < $< > $@

%.dvi: %.tex
	## start of linting stuff
	# check kanji-code of the tex file.
	iconv -f iso-2022-jp -t iso-2022-jp < $< > /dev/null
	# check some obvious spelling mistakes Debian勉強会標準以外の表記を使った場合ここがエラーになります。修正してからコミットしてください。
	./utils/spelllint.sh $<
	# check that pre-commit hook is installed.
	# if this fails, please do:
	# cp git-pre-commit.sh .git/hooks/pre-commit
	# コミットフックをインストールしていないとここでエラーになります。ここがエラーになったらエラーを放置しないで修正すること!
	## end of linting stuff
	platex -halt-on-error -kanji=jis $< # create draft input
	-mendex $(<:%.tex=%)
	platex -halt-on-error -kanji=jis $< # create draft content with correct spacing for index and toc
	-mendex $(<:%.tex=%) # recreate index with correct page number
	platex -halt-on-error -kanji=jis $< # recreate toc with correct page number

%.eps: %.svg
	inkscape --export-eps $@ $<

clean:
	-rm -f *.dvi *.aux *.toc *~ *.log *.waux *.out _whizzy_* *.snm *.nav *.jqz *.ind *.ilg *.idx *.idv *.lg *.xref *.4ct *.4tc *.css
	# 一度全部のファイルをpublishしたものとみなす。古いファイルを全部アップロードするのを回避します
	-touch $(RELEASEFILES)

.PHONY: deb clean all check

check-syntax:
	$(CC) -c -O2 -Wall $(CHK_SOURCES) -o/dev/null $(shell pkg-config --cflags gtk+-2.0)
