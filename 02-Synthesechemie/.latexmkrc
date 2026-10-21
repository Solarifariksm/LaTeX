% latexmk-Konfiguration: Repo-Root in den LaTeX-Suchpfad aufnehmen,
% damit \input{Praeambel.tex} die zentrale Praeambel immer findet,
% egal auf welcher Ebene dieses Protokoll liegt.
ensure_path('TEXINPUTS', '../', '../../');
