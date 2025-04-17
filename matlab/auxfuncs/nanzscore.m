function A = nanzscore(A);
A = (A - nanmean(A))./nanstd(A);
end