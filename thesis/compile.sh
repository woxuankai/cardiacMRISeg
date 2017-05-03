#export TEXINPUTS=./dependencies//:
#export TEXMFDBS=./dependencies:
jobname=thesis
./clean.sh
rm $jobname.pdf
pdflatex ./$jobname.tex
makeindex -s $jobname.ist -t $jobname.glg -o $jobname.gls $jobname.glo
makeindex -s $jobname.ist -t $jobname.alg -o $jobname.acr $jobname.acn
bibtex ./$jobname.aux
bibtex ./publications.aux
pdflatex ./$jobname.tex
makeindex -s $jobname.ist -t $jobname.glg -o $jobname.gls $jobname.glo
makeindex -s $jobname.ist -t $jobname.alg -o $jobname.acr $jobname.acn
pdflatex ./$jobname.tex
./clean.sh
clear
echo ****************************************************************************
echo 正式编译前应该访问https://github.com/shifujun/UESTCthesis检查模板是否有更新！
echo ****************************************************************************
