function [ matmat, matmat_byindex] = genbestmmatrix(nodes, data,~,~)
[~,matmat_byindex] = pdist2(nodes',data','euclidean','Smallest',1);
matmat = data(matmat_byindex);
end