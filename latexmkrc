$pdf_mode = 5;         # XeLaTeX
$xelatex = 'xelatex -interaction=nonstopmode -halt-on-error -file-line-error %O %S';
$bibtex_use = 2;       # biblatex/biber
$max_repeat = 5;

# Enable shell escape only when the user explicitly requests TikZ caching.
if ($ENV{'PROPOSAL_TIKZ_CACHE'} || -e 'tikz-cache/enable.tex') {
    $xelatex = 'xelatex -shell-escape -interaction=nonstopmode -halt-on-error -file-line-error %O %S';
}
