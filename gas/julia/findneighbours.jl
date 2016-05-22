function findneighbours(s,C)
row, col = findnz(C);
neighbours = [];
for i = 1:length(row)
    if row[i] == s
        neighbours = vcat(neighbours, col[i]);
    end
end
return neighbours
end
